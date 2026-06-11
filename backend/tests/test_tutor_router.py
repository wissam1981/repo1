from app.models import Contract, Quiz, User


def _make_contract(db_session) -> Contract:
    """Create a contract owned by the fixture test user (test@example.com)."""
    user = db_session.query(User).filter_by(email="test@example.com").one()
    contract = Contract(user_id=user.id, title="Test Contract", file_url="s3://x")
    db_session.add(contract)
    db_session.commit()
    return contract


def test_create_tutor_session(client, db_session):
    contract = _make_contract(db_session)
    resp = client.post(f"/tutor/sessions/{contract.id}")
    assert resp.status_code == 201
    body = resp.json()
    assert body["difficulty"] == 1
    assert body["messages"] == []
    assert body["contract_id"] == contract.id


def test_create_session_rejects_foreign_contract(client, db_session):
    other = User(email="other@example.com", auth_provider="google")
    db_session.add(other)
    db_session.flush()
    contract = Contract(user_id=other.id, title="Theirs", file_url="s3://y")
    db_session.add(contract)
    db_session.commit()

    resp = client.post(f"/tutor/sessions/{contract.id}")
    assert resp.status_code == 403


def test_send_message_to_session(client, db_session, fake_claude):
    contract = _make_contract(db_session)
    create_resp = client.post(f"/tutor/sessions/{contract.id}")
    session_id = create_resp.json()["id"]

    fake_claude._responses = [{
        "message": "Clause 1 sets a 12-month term.",
        "new_difficulty": 2,
    }]

    resp = client.post(f"/tutor/sessions/{session_id}/message", json={
        "session_id": session_id,
        "message": "What does clause 1 say?",
    })
    assert resp.status_code == 200
    body = resp.json()
    assert len(body["messages"]) == 2  # user + assistant
    assert body["messages"][0]["role"] == "user"
    assert body["messages"][1]["role"] == "assistant"
    assert body["difficulty"] == 2


def test_get_and_list_sessions(client, db_session):
    contract = _make_contract(db_session)
    create_resp = client.post(f"/tutor/sessions/{contract.id}")
    session_id = create_resp.json()["id"]

    get_resp = client.get(f"/tutor/sessions/{session_id}")
    assert get_resp.status_code == 200
    assert get_resp.json()["id"] == session_id

    list_resp = client.get("/tutor/sessions")
    assert list_resp.status_code == 200
    ids = [s["id"] for s in list_resp.json()]
    assert session_id in ids


def test_quiz_submission_updates_user_cefr(client, db_session):
    user = db_session.query(User).filter_by(email="test@example.com").one()
    assert user.cefr_level == "A1"

    quiz = Quiz(contract_id=None, clause_id=None, quiz_type="mcq", questions=[
        {"type": "mcq", "question": "Q?", "options": ["a", "b"], "correct_index": 0}
    ])
    db_session.add(quiz)
    db_session.commit()

    resp = client.post("/quizzes/submit", json={"quiz_id": quiz.id, "answers": [0]})
    assert resp.status_code == 201

    db_session.refresh(user)
    # A perfect score (1.0) → C2
    assert user.cefr_level == "C2"
