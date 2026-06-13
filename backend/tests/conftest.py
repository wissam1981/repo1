import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.db import Base, get_db
from app.deps import get_claude, get_current_user
from app.main import app
from app.models import User

TEST_DATABASE_URL = "sqlite://"
TEST_JWT_SECRET = "test-jwt-secret-hermetic"
TEST_ANTHROPIC_API_KEY = "sk-ant-test-dummy"
TEST_GOOGLE_CLIENT_ID = "test-google-client-id"
TEST_APPLE_CLIENT_ID = "test-apple-client-id"


@pytest.fixture(autouse=True)
def _hermetic_settings(monkeypatch):
    """Ensure every test runs with deterministic env vars, independent of .env."""
    import app.db as _db
    from app.config import get_settings

    get_settings.cache_clear()
    # Reset any cached session factory so it re-creates with the test settings.
    _db._session_factory = None
    monkeypatch.setenv("DATABASE_URL", TEST_DATABASE_URL)
    monkeypatch.setenv("JWT_SECRET", TEST_JWT_SECRET)
    monkeypatch.setenv("ANTHROPIC_API_KEY", TEST_ANTHROPIC_API_KEY)
    monkeypatch.setenv("GOOGLE_CLIENT_ID", TEST_GOOGLE_CLIENT_ID)
    monkeypatch.setenv("APPLE_CLIENT_ID", TEST_APPLE_CLIENT_ID)
    yield
    get_settings.cache_clear()
    _db._session_factory = None


@pytest.fixture
def db_session():
    engine = create_engine(
        "sqlite://",
        future=True,
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    Base.metadata.create_all(engine)
    TestingSession = sessionmaker(bind=engine, expire_on_commit=False, future=True)
    session = TestingSession()
    try:
        yield session
    finally:
        session.close()


class FakeClaude:
    """Returns queued responses in order; assert on .calls."""
    def __init__(self, responses):
        self._responses = list(responses)
        self.calls = []

    def complete_json(self, system, user, *, fast=False):
        self.calls.append({"system": system, "user": user, "fast": fast})
        return self._responses.pop(0)


@pytest.fixture
def fake_claude():
    return FakeClaude(responses=[])


@pytest.fixture(autouse=True)
def _bg_tasks_use_test_db(monkeypatch, db_session):
    """Route background contract processing to the test session.

    The upload endpoint schedules _process_contract as a background task,
    which opens its own session via db._factory(). TestClient executes
    background tasks synchronously after the response - point them at the
    same in-memory test database so processed clauses are visible to asserts.
    """
    from app.routers import contracts_router

    monkeypatch.setattr(
        contracts_router, "_factory", lambda: (lambda: db_session))


@pytest.fixture
def client(db_session, fake_claude):
    user = User(email="test@example.com", auth_provider="google")
    db_session.add(user)
    db_session.commit()

    app.dependency_overrides[get_db] = lambda: db_session
    app.dependency_overrides[get_claude] = lambda: fake_claude
    app.dependency_overrides[get_current_user] = lambda: user
    yield TestClient(app)
    app.dependency_overrides.clear()
