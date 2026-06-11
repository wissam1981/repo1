from app.models import Clause, Contract, Quiz, QuizAttempt, User


def _make_clause(db_session) -> Clause:
    """Create a clause owned by the fixture test user (test@example.com)."""
    user = db_session.query(User).filter_by(email="test@example.com").one()
    contract = Contract(user_id=user.id, title="T", file_url="s3://x")
    db_session.add(contract)
    db_session.flush()
    clause = Clause(contract_id=contract.id, order=1, original_text="The term is 12 months.")
    db_session.add(clause)
    db_session.commit()
    return clause


def test_generate_quiz_returns_201(client, db_session, fake_claude):
    clause = _make_clause(db_session)
    fake_claude._responses = [{
        "questions": [
            {"type": "mcq", "question": "Q1?", "options": ["a", "b", "c", "d"], "correct_index": 0},
            {"type": "mcq", "question": "Q2?", "options": ["a", "b", "c", "d"], "correct_index": 1},
        ]
    }]

    resp = client.post("/quizzes/generate", json={
        "clause_id": clause.id,
        "quiz_type": "mcq",
        "count": 2,
    })
    assert resp.status_code == 201
    body = resp.json()
    assert body["quiz_type"] == "mcq"
    assert body["id"] is not None


def test_submit_quiz_returns_attempt(client, db_session):
    quiz = Quiz(contract_id=None, clause_id=None, quiz_type="mcq", questions=[
        {"type": "mcq", "question": "Q?", "options": ["a", "b", "c"], "correct_index": 1}
    ])
    db_session.add(quiz)
    db_session.commit()

    resp = client.post("/quizzes/submit", json={
        "quiz_id": quiz.id,
        "answers": [1],  # correct
    })
    assert resp.status_code == 201
    body = resp.json()
    assert body["score"] == 1.0  # 100% if all correct


def test_quiz_history(client, db_session):
    resp = client.get("/quizzes/history")
    assert resp.status_code == 200
    assert isinstance(resp.json(), list)


def test_generate_quiz_rejects_unowned_clause(client, db_session, fake_claude):
    other = User(email="other@example.com", auth_provider="google")
    db_session.add(other)
    db_session.flush()
    contract = Contract(user_id=other.id, title="X", file_url="s3://y")
    db_session.add(contract)
    db_session.flush()
    clause = Clause(contract_id=contract.id, order=1, original_text="secret")
    db_session.add(clause)
    db_session.commit()

    resp = client.post("/quizzes/generate", json={
        "clause_id": clause.id,
        "quiz_type": "mcq",
        "count": 1,
    })
    assert resp.status_code == 403


def test_submit_unknown_quiz_returns_404(client):
    resp = client.post("/quizzes/submit", json={"quiz_id": 99999, "answers": [0]})
    assert resp.status_code == 404
