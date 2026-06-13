"""Tap-a-word lookups must respect the contract's own definitions.

Regression: tapping "NOC" returned the generic meaning (No Objection
Certificate) although the contract defines NOC as North Oil Company.
"""
from app.models import Clause, Contract, User


def _setup(db_session, user_email="test@example.com"):
    user = db_session.query(User).filter_by(email=user_email).one()
    contract = Contract(user_id=user.id, title="Kirkuk", file_url="local://k",
                        status="explained")
    db_session.add(contract)
    db_session.flush()
    defn = Clause(
        contract_id=contract.id, order=1, is_definition=True,
        original_text='1.30 "NOC" means North Oil Company, a state company.',
    )
    operative = Clause(
        contract_id=contract.id, order=2, is_definition=False,
        original_text="7.1 The Contractor shall report to NOC monthly.",
    )
    db_session.add_all([defn, operative])
    db_session.commit()
    return operative


def test_tap_includes_contract_definition_in_prompt(client, db_session,
                                                    fake_claude):
    operative = _setup(db_session)
    fake_claude._responses = [
        {"meaning_en": "North Oil Company", "meaning_ar": "شركة نفط الشمال", "example": "..."}]

    resp = client.post("/vocabulary/tap",
                       json={"term": "NOC", "clause_id": operative.id})
    assert resp.status_code == 201

    prompt = fake_claude.calls[-1]["user"]
    assert "North Oil Company" in prompt          # contract definition passed
    assert "MUST follow this definition" in prompt
    assert "report to NOC monthly" in prompt       # tapped clause as context


def test_tap_without_definition_still_passes_clause_context(
        client, db_session, fake_claude):
    operative = _setup(db_session)
    fake_claude._responses = [{"meaning_en": "monthly", "meaning_ar": "شهرياً", "example": "..."}]

    resp = client.post("/vocabulary/tap",
                       json={"term": "monthly", "clause_id": operative.id})
    assert resp.status_code == 201

    prompt = fake_claude.calls[-1]["user"]
    assert "MUST follow this definition" not in prompt
    assert "report to NOC monthly" in prompt
