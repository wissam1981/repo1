from app.models import User, Contract, Clause, Quiz, QuizAttempt
from app.services.quizzes import generate_quiz, grade_quiz_submission


def test_generate_mcq_quiz(db_session, fake_claude):
    user = User(email="u@e.com", auth_provider="google")
    db_session.add(user)
    db_session.flush()
    contract = Contract(user_id=user.id, title="T", file_url="s3://x")
    db_session.add(contract)
    db_session.flush()
    clause = Clause(contract_id=contract.id, order=1, original_text="The term is 12 months.")
    db_session.add(clause)
    db_session.commit()

    fake_claude._responses = [{
        "questions": [
            {
                "type": "mcq",
                "question": "What is the term?",
                "options": ["6 months", "12 months", "24 months", "36 months"],
                "correct_index": 1,
            }
        ]
    }]

    quiz = generate_quiz(db_session, fake_claude, clause_id=clause.id, quiz_type="mcq", count=1)
    assert quiz.quiz_type == "mcq"
    assert len(quiz.questions) == 1
    assert quiz.questions[0]["question"] == "What is the term?"


def test_grade_open_answer(db_session, fake_claude):
    user = User(email="u@e.com", auth_provider="google")
    db_session.add(user)
    db_session.flush()
    quiz_obj = Quiz(contract_id=None, clause_id=None, quiz_type="open", questions=[
        {"type": "open", "question": "Explain clause 5."}
    ])
    db_session.add(quiz_obj)
    db_session.flush()
    attempt = QuizAttempt(user_id=user.id, quiz_id=quiz_obj.id, answers=["User's answer text here."])
    db_session.add(attempt)
    db_session.flush()

    fake_claude._responses = [{
        "score": 0.75,
        "feedback": "Good explanation, but missed one key detail.",
    }]

    grade_quiz_submission(db_session, fake_claude, attempt)
    db_session.refresh(attempt)
    assert attempt.score == 0.75
    assert "missed" in attempt.feedback.lower()


def test_grade_tolerates_missing_question_type(db_session):
    """GPT sometimes omits per-question 'type'; grading must not crash."""
    from app.models import Quiz, QuizAttempt, User
    from app.services.quizzes import grade_quiz_submission

    user = User(email="g@e.com", auth_provider="guest")
    db_session.add(user)
    db_session.flush()
    quiz = Quiz(contract_id=None, clause_id=None, quiz_type="mcq", questions=[
        {"question": "Q1?", "options": ["a", "b", "c", "d"], "correct_index": 1},
        {"question": "Q2?", "options": ["a", "b", "c", "d"], "correct_index": 2},
    ])
    db_session.add(quiz)
    db_session.flush()
    attempt = QuizAttempt(user_id=user.id, quiz_id=quiz.id, answers=[1, 0])
    db_session.add(attempt)
    db_session.commit()

    grade_quiz_submission(db_session, None, attempt)  # claude unused for mcq
    db_session.refresh(attempt)
    assert attempt.score == 0.5
