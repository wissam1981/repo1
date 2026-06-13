"""Tests for vocabulary router endpoints."""
from datetime import datetime, timezone, timedelta

import pytest

from app.models import Word, Review


def test_save_word_returns_201(client):
    resp = client.post("/vocabulary/words", json={
        "term": "lease",
        "meaning": "rental agreement",
        "example": "The property lease is 5 years.",
        "clause_id": None,
    })
    assert resp.status_code == 201
    body = resp.json()
    assert body["term"] == "lease"
    assert body["meaning"] == "rental agreement"
    assert body["example"] == "The property lease is 5 years."
    assert body["id"] is not None


def test_save_word_creates_initial_review(client, db_session):
    """POSTing a word should create an initial review record due today."""
    resp = client.post("/vocabulary/words", json={
        "term": "indemnify",
        "meaning": "compensate for loss",
        "example": "The seller shall indemnify the buyer.",
        "clause_id": None,
    })
    assert resp.status_code == 201
    word_id = resp.json()["id"]

    review = db_session.query(Review).filter_by(word_id=word_id).one()
    assert review.ease == 2.5
    assert review.repetitions == 0
    assert review.interval_days == 1
    assert review.due_date.date() == datetime.now(timezone.utc).date()


def test_list_due_words_returns_200(client):
    """GET /vocabulary/due returns an empty list when nothing is due."""
    resp = client.get("/vocabulary/due")
    assert resp.status_code == 200
    assert isinstance(resp.json(), list)


def test_list_due_words_returns_due_word(client, db_session):
    """A word whose review is due today must appear in the list."""
    # Create a word and due review directly in db
    from app.models import User
    user = db_session.query(User).filter_by(email="test@example.com").one()

    word = Word(user_id=user.id, term="arbitration", meaning="dispute resolution", example="See clause 5.", clause_id=None)
    db_session.add(word)
    db_session.flush()

    review = Review(
        word_id=word.id,
        due_date=datetime.now(timezone.utc),
        ease=2.5, interval_days=1, repetitions=0, last_result=None,
    )
    db_session.add(review)
    db_session.commit()

    resp = client.get("/vocabulary/due")
    assert resp.status_code == 200
    terms = [w["term"] for w in resp.json()]
    assert "arbitration" in terms


def test_list_due_words_excludes_future_reviews(client, db_session):
    """A word whose review is in the future must NOT appear in the list."""
    from app.models import User
    user = db_session.query(User).filter_by(email="test@example.com").one()

    word = Word(user_id=user.id, term="future_word", meaning="m", example="e", clause_id=None)
    db_session.add(word)
    db_session.flush()

    review = Review(
        word_id=word.id,
        due_date=datetime.now(timezone.utc) + timedelta(days=10),
        ease=2.5, interval_days=1, repetitions=0, last_result=None,
    )
    db_session.add(review)
    db_session.commit()

    resp = client.get("/vocabulary/due")
    assert resp.status_code == 200
    terms = [w["term"] for w in resp.json()]
    assert "future_word" not in terms


def test_record_review_outcome_returns_200(client, db_session):
    """PUT /vocabulary/reviews/{id} updates the review schedule."""
    from app.models import User
    user = db_session.query(User).filter_by(email="test@example.com").one()

    word = Word(user_id=user.id, term="warranty", meaning="guarantee", example="The warranty lasts 1 year.", clause_id=None)
    db_session.add(word)
    db_session.flush()

    review = Review(
        word_id=word.id,
        due_date=datetime.now(timezone.utc),
        ease=2.5, interval_days=1, repetitions=0, last_result=None,
    )
    db_session.add(review)
    db_session.commit()

    resp = client.put(f"/vocabulary/reviews/{review.id}", json={"review_id": review.id, "quality": 4})
    assert resp.status_code == 200
    assert resp.json()["status"] == "ok"

    db_session.refresh(review)
    assert review.repetitions == 1
    assert review.interval_days == 3
    assert review.last_result == 4


def test_record_review_outcome_404_for_unknown(client):
    """PUT with a non-existent review_id returns 404."""
    resp = client.put("/vocabulary/reviews/9999", json={"review_id": 9999, "quality": 3})
    assert resp.status_code == 404
