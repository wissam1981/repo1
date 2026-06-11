"""Negative-path tests for authentication and contract ownership enforcement.

These tests intentionally do NOT override get_current_user so that the real
JWT-verification logic is exercised.  Only get_db is overridden to supply an
in-memory SQLite database seeded with the data each test needs.
"""
import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.auth import create_jwt
from app.db import Base, get_db
from app.deps import get_claude
from app.main import app
from app.models import Contract, User
from tests.conftest import TEST_JWT_SECRET, FakeClaude


def _make_test_session():
    """Create a fresh in-memory SQLite session with all tables."""
    engine = create_engine(
        "sqlite://",
        future=True,
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    Base.metadata.create_all(engine)
    Session = sessionmaker(bind=engine, expire_on_commit=False, future=True)
    return Session()


@pytest.fixture()
def real_auth_client():
    """TestClient with get_db overridden but get_current_user NOT overridden."""
    session = _make_test_session()

    def override_get_db():
        yield session

    app.dependency_overrides[get_db] = override_get_db
    app.dependency_overrides[get_claude] = lambda: FakeClaude(responses=[])
    yield TestClient(app, raise_server_exceptions=False), session
    app.dependency_overrides.clear()
    session.close()


def test_no_auth_header_returns_403_or_401(real_auth_client):
    """A request with no Authorization header must be rejected."""
    client, _ = real_auth_client
    resp = client.get("/contracts/999")
    assert resp.status_code in (401, 403)


def test_garbage_bearer_token_returns_401(real_auth_client):
    """A malformed / garbage bearer token must yield 401 Unauthorized."""
    client, _ = real_auth_client
    resp = client.get("/contracts/999", headers={"Authorization": "Bearer this-is-not-a-jwt"})
    assert resp.status_code == 401


def test_valid_jwt_for_wrong_user_returns_404(real_auth_client):
    """
    A valid JWT for user A must not expose a contract that belongs to user B.
    The endpoint returns 404 (not found / not yours) rather than leaking info.
    """
    client, session = real_auth_client

    # Create two users.
    user_a = User(email="usera@example.com", auth_provider="google")
    user_b = User(email="userb@example.com", auth_provider="google")
    session.add_all([user_a, user_b])
    session.commit()
    session.refresh(user_a)
    session.refresh(user_b)

    # Create a contract owned by user B.
    contract = Contract(
        user_id=user_b.id,
        title="User B's Contract",
        file_url="local://b.docx",
        status="uploaded",
    )
    session.add(contract)
    session.commit()
    session.refresh(contract)

    # Build a valid JWT for user A.
    token = create_jwt(user_a.id, secret=TEST_JWT_SECRET)

    resp = client.get(
        f"/contracts/{contract.id}",
        headers={"Authorization": f"Bearer {token}"},
    )
    assert resp.status_code == 404
