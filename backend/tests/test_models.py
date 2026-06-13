from sqlalchemy import create_engine
from sqlalchemy.orm import Session
from app.db import Base
from app.models import User, Contract, Clause

def test_create_user_contract_clause():
    engine = create_engine("sqlite://", future=True)
    Base.metadata.create_all(engine)
    with Session(engine) as db:
        user = User(email="a@b.com", auth_provider="google")
        db.add(user)
        db.flush()
        contract = Contract(user_id=user.id, title="Test", file_url="s3://x", status="uploaded")
        db.add(contract)
        db.flush()
        clause = Clause(contract_id=contract.id, order=1, original_text="The term is 12 months.")
        db.add(clause)
        db.commit()
        assert clause.id is not None
        assert clause.contract_id == contract.id
        assert user.cefr_level == "A1"
