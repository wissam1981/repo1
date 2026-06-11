"""Tests for natural AI pronunciation endpoint."""
from app.auth import create_jwt
from app.main import app
from app.models import User
from app.routers.vocabulary_router import _AUDIO_CACHE, get_speech
from tests.conftest import TEST_JWT_SECRET


def _token(db_session) -> str:
    user = db_session.query(User).filter_by(email="test@example.com").one()
    return create_jwt(user.id, TEST_JWT_SECRET, algorithm="HS256",
                      expire_minutes=60)


def test_pronounce_returns_audio_and_caches(client, db_session):
    _AUDIO_CACHE.clear()
    token = _token(db_session)
    calls = []

    def fake_synth(text):
        calls.append(text)
        return b"FAKE-MP3"

    app.dependency_overrides[get_speech] = lambda: fake_synth

    r1 = client.get(f"/vocabulary/pronounce?text=Abandonment&token={token}")
    assert r1.status_code == 200
    assert r1.headers["content-type"].startswith("audio/mpeg")
    assert r1.content == b"FAKE-MP3"

    # Second request for the same text is served from cache (no new synth).
    r2 = client.get(f"/vocabulary/pronounce?text=abandonment&token={token}")
    assert r2.status_code == 200
    assert len(calls) == 1


def test_pronounce_invalid_token_401(client):
    r = client.get("/vocabulary/pronounce?text=hello&token=garbage")
    assert r.status_code == 401


def test_pronounce_synth_failure_503(client, db_session):
    _AUDIO_CACHE.clear()
    token = _token(db_session)

    def broken(_):
        raise RuntimeError("no credit")

    app.dependency_overrides[get_speech] = lambda: broken
    r = client.get(f"/vocabulary/pronounce?text=indemnity&token={token}")
    assert r.status_code == 503
