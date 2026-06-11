"""Tests for tap-a-word: AI lookup + auto-save while reading a clause."""
from app.models import Review, Word


def test_tap_word_looks_up_and_saves(client, fake_claude, db_session):
    fake_claude._responses = [
        {"meaning": "Giving up a well permanently (التخلي عن البئر)",
         "example": "The contractor proposed the abandonment of Well 7."},
    ]
    resp = client.post("/vocabulary/tap", json={"term": "abandonment"})
    assert resp.status_code == 201
    body = resp.json()
    assert body["term"] == "abandonment"
    assert "meaning" in body and body["meaning"]
    assert "example" in body and body["example"]

    # Word persisted with an initial SM-2 review scheduled.
    word = db_session.query(Word).filter_by(term="abandonment").one()
    assert db_session.query(Review).filter_by(word_id=word.id).count() == 1


def test_tap_word_ai_failure_returns_503(client, fake_claude, db_session):
    fake_claude._responses = []  # FakeClaude raises when exhausted
    resp = client.post("/vocabulary/tap", json={"term": "indemnity"})
    assert resp.status_code == 503
    assert db_session.query(Word).filter_by(term="indemnity").count() == 0
