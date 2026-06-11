from datetime import datetime, timezone, timedelta
from sqlalchemy.orm import Session

from app.models import Word, Review, Clause, User
from app.sm2 import InitialReview, apply_sm2


def save_word(
    db: Session, user: User, term: str, meaning: str, example: str, clause: Clause | None = None
) -> Word:
    word = Word(user_id=user.id, term=term, meaning=meaning, example=example,
                clause_id=clause.id if clause else None)
    db.add(word)
    db.flush()
    initial = InitialReview()
    review = Review(
        word_id=word.id,
        due_date=datetime.now(timezone.utc),
        ease=initial.ease,
        interval_days=initial.interval_days,
        repetitions=initial.repetitions,
        last_result=None,
    )
    db.add(review)
    db.commit()
    return word


def list_due_words(db: Session, user: User) -> list[Word]:
    now = datetime.now(timezone.utc)
    due_reviews = db.query(Review).join(Word).filter(
        Word.user_id == user.id,
        Review.due_date <= now,
    ).all()
    return [review.word for review in due_reviews]


def apply_review_outcome(db: Session, review: Review, quality: int) -> None:
    current_state = type('ReviewState', (), {
        'ease': review.ease,
        'interval_days': review.interval_days,
        'repetitions': review.repetitions,
    })()
    next_state = apply_sm2(current_state, quality)
    review.ease = next_state.ease
    review.interval_days = next_state.interval_days
    review.repetitions = next_state.repetitions
    review.last_result = quality
    review.due_date = datetime.now(timezone.utc) + timedelta(days=next_state.interval_days)
    db.commit()
