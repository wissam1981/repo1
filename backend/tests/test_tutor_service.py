from app.models import User, Contract, Clause, TutorSession
from app.services.tutor import (
    create_session,
    add_message,
    get_session_context,
    get_tutor_response,
)


def _make_user_and_contract(db_session, with_clause=False):
    user = User(email="u@e.com", auth_provider="google")
    db_session.add(user)
    db_session.flush()
    contract = Contract(user_id=user.id, title="Test Contract", file_url="s3://x")
    db_session.add(contract)
    db_session.flush()
    if with_clause:
        clause = Clause(contract_id=contract.id, order=1, original_text="The term is 12 months.")
        db_session.add(clause)
    db_session.commit()
    return user, contract


def test_create_tutor_session(db_session):
    user, contract = _make_user_and_contract(db_session)

    session = create_session(db_session, user, contract)
    assert session.user_id == user.id
    assert session.contract_id == contract.id
    assert session.difficulty == 1
    assert session.messages == []


def test_add_message_to_session(db_session):
    user, contract = _make_user_and_contract(db_session)

    session = create_session(db_session, user, contract)
    add_message(db_session, session, "user", "What does clause 1 say?")
    add_message(db_session, session, "assistant", "Clause 1 says...")

    db_session.refresh(session)
    assert len(session.messages) == 2
    assert session.messages[0]["role"] == "user"
    assert session.messages[1]["role"] == "assistant"


def test_get_session_context_includes_contract_and_messages(db_session):
    user, contract = _make_user_and_contract(db_session, with_clause=True)

    session = create_session(db_session, user, contract)
    add_message(db_session, session, "user", "What's the term?")

    context = get_session_context(session)
    assert "Test Contract" in context
    assert "12 months" in context
    assert "What's the term?" in context


def test_tutor_turn(db_session, fake_claude):
    user, contract = _make_user_and_contract(db_session, with_clause=True)

    session = create_session(db_session, user, contract)
    add_message(db_session, session, "user", "What's the term?")

    fake_claude._responses = [{
        "message": "The contract term is 12 months.",
        "new_difficulty": 1,
    }]

    response = get_tutor_response(db_session, fake_claude, session)

    assert response["message"] == "The contract term is 12 months."
    db_session.refresh(session)
    assert len(session.messages) == 2  # user + assistant
    assert session.messages[1]["role"] == "assistant"


def test_context_labels_real_article_numbers(db_session):
    """Citations must use the contract's printed article numbers, not the
    app's internal clause order (which reorders definitions first)."""
    from app.models import Clause, Contract, TutorSession, User
    from app.services.tutor import get_session_context

    user = User(email="a@e.com", auth_provider="guest")
    db_session.add(user)
    db_session.flush()
    contract = Contract(user_id=user.id, title="T", file_url="local://x")
    db_session.add(contract)
    db_session.flush()
    # app order 1 holds the contract's Article 19.5 (definitions-first shuffle)
    db_session.add(Clause(contract_id=contract.id, order=1,
                          original_text="19.5 Contractor shall be paid per "
                                        "the Performance Factor."))
    session = TutorSession(user_id=user.id, contract_id=contract.id,
                           messages=[])
    db_session.add(session)
    db_session.commit()

    ctx = get_session_context(session)
    assert "[Article 19.5]" in ctx
    assert "Clause 1:" not in ctx
