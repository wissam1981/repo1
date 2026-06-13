from datetime import datetime, timezone, timedelta
from app.models import User, Contract, Clause, Word, Review
from app.services.vocabulary import save_word, list_due_words, apply_review_outcome
from app.sm2 import InitialReview

def test_save_word_creates_word_and_initial_review(db_session):
    user = User(email="u@e.com", auth_provider="google")
    db_session.add(user)
    db_session.flush()
    contract = Contract(user_id=user.id, title="T", file_url="s3://x")
    db_session.add(contract)
    db_session.flush()
    clause = Clause(contract_id=contract.id, order=1, original_text="Term.")
    db_session.add(clause)
    db_session.commit()

    word_obj = save_word(db_session, user, "termination", "ending", "The contract termination clause.", clause)
    assert word_obj.term == "termination"
    assert word_obj.user_id == user.id
    db_session.refresh(word_obj)
    review = db_session.query(Review).filter_by(word_id=word_obj.id).one()
    assert review.due_date.date() == datetime.now(timezone.utc).date()
    assert review.ease == 2.5

def test_list_due_words_filters_by_date(db_session):
    user = User(email="u@e.com", auth_provider="google")
    db_session.add(user)
    db_session.commit()
    word1 = Word(user_id=user.id, term="word1", meaning="m1", example="e1", clause_id=None)
    word2 = Word(user_id=user.id, term="word2", meaning="m2", example="e2", clause_id=None)
    db_session.add_all([word1, word2])
    db_session.flush()
    review1 = Review(word_id=word1.id, due_date=datetime.now(timezone.utc), ease=2.5, interval_days=1, repetitions=0, last_result=None)
    review2 = Review(word_id=word2.id, due_date=datetime.now(timezone.utc) + timedelta(days=10), ease=2.5, interval_days=1, repetitions=0, last_result=None)
    db_session.add_all([review1, review2])
    db_session.commit()
    due = list_due_words(db_session, user)
    assert len(due) == 1
    assert due[0].term == "word1"

def test_apply_review_outcome_updates_schedule(db_session):
    user = User(email="u@e.com", auth_provider="google")
    db_session.add(user)
    db_session.commit()
    word = Word(user_id=user.id, term="test", meaning="m", example="e", clause_id=None)
    db_session.add(word)
    db_session.flush()
    review = Review(word_id=word.id, due_date=datetime.now(timezone.utc), ease=2.5, interval_days=1, repetitions=0, last_result=None)
    db_session.add(review)
    db_session.commit()
    apply_review_outcome(db_session, review, quality=4)
    db_session.refresh(review)
    assert review.repetitions == 1
    assert review.interval_days == 3
    assert review.last_result == 4
