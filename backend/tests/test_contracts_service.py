from app.models import User, Contract
from app.services.contracts import split_and_explain
from tests.conftest import FakeClaude


def test_split_and_explain_persists_clauses(db_session):
    user = User(email="u@e.com", auth_provider="google")
    db_session.add(user)
    db_session.commit()
    contract = Contract(user_id=user.id, title="T", file_url="s3://x", status="uploaded")
    db_session.add(contract)
    db_session.commit()

    claude = FakeClaude(responses=[
        {"clauses": ["The term of this Agreement is twelve (12) months.",
                     "Payment shall be made monthly within thirty (30) days."]},  # split
        {"simple_en": "Simple 1", "arabic": "بسيط 1", "key_terms": [{"term": "term", "meaning": "m"}]},
        {"simple_en": "Simple 2", "arabic": "بسيط 2", "key_terms": []},
    ])

    split_and_explain(db_session, claude, contract, "Full contract text here.")
    db_session.refresh(contract)

    assert contract.status == "explained"
    assert len(contract.clauses) == 2
    assert contract.clauses[0].order == 1
    assert contract.clauses[0].simple_en == "Simple 1"
    assert contract.clauses[1].key_terms == []
    assert len(claude.calls) == 3  # 1 split + 2 explain
