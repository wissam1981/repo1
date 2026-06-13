# Backend Foundation & Contract Ingestion — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a tested FastAPI backend that authenticates users (Google/Apple → JWT), accepts an uploaded contract (PDF/Word), extracts and splits it into clauses, and explains each clause via Claude — with all AI calls mockable in tests.

**Architecture:** A stateless FastAPI service backed by PostgreSQL (via SQLAlchemy + Alembic). Text extraction is pure-Python (`pypdf`, `python-docx`). All Claude calls go through a single thin client wrapper that is dependency-injected so tests can substitute a fake. Endpoints validate Claude's structured JSON output before persisting.

**Tech Stack:** Python 3.12, FastAPI, Uvicorn, SQLAlchemy 2.x, Alembic, PostgreSQL, Pydantic v2, `anthropic` SDK, `pypdf`, `python-docx`, `python-jose` (JWT), `pytest`, `httpx` (test client).

This is the first of several plans. Later plans cover: vocabulary + spaced repetition, quizzes + grading, the AI tutor + CEFR estimation, the daily plan/dashboard, and the Flutter frontend.

---

## File Structure

```
backend/
  pyproject.toml                # deps + tool config
  .env.example                  # config template
  alembic.ini                   # migration config
  app/
    __init__.py
    main.py                     # FastAPI app + router wiring
    config.py                   # Settings (env-driven)
    db.py                       # engine, session, Base
    models.py                   # SQLAlchemy ORM models
    schemas.py                  # Pydantic request/response models
    auth.py                     # provider token verify + JWT issue/verify
    deps.py                     # FastAPI dependencies (db session, current user)
    claude_client.py            # thin Claude wrapper (injectable)
    extraction.py               # PDF/Word text extraction (pure)
    services/
      __init__.py
      contracts.py              # upload→extract→split→explain orchestration
    routers/
      __init__.py
      auth_router.py            # POST /auth/login
      contracts_router.py       # POST /contracts, GET /contracts/{id}
  alembic/
    env.py
    versions/                   # generated migrations
  tests/
    __init__.py
    conftest.py                 # fixtures: test db, client, fake claude
    fixtures/
      sample.pdf                # tiny generated test PDF
      sample.docx               # tiny generated test DOCX
    test_extraction.py
    test_auth.py
    test_claude_client.py
    test_contracts_service.py
    test_contracts_router.py
```

**Responsibilities**
- `extraction.py` — bytes + filename → plain text. No I/O beyond parsing. Pure and trivially testable.
- `claude_client.py` — one method per AI task; takes a prompt, returns parsed JSON. Injectable so tests pass a fake.
- `services/contracts.py` — business logic: orchestrates extraction → split → explain → persist. No HTTP concerns.
- `routers/*` — HTTP only: parse request, call service, shape response.
- `auth.py` — verify a provider ID token, issue our JWT, decode our JWT.

---

## Task 1: Project scaffold

**Files:**
- Create: `backend/pyproject.toml`
- Create: `backend/.env.example`
- Create: `backend/app/__init__.py`
- Create: `backend/app/main.py`
- Create: `backend/tests/__init__.py`
- Create: `backend/tests/test_health.py`

- [ ] **Step 1: Create `pyproject.toml`**

```toml
[project]
name = "contract-english-trainer-backend"
version = "0.1.0"
requires-python = ">=3.12"
dependencies = [
    "fastapi>=0.111",
    "uvicorn[standard]>=0.30",
    "sqlalchemy>=2.0",
    "alembic>=1.13",
    "psycopg[binary]>=3.1",
    "pydantic>=2.7",
    "pydantic-settings>=2.3",
    "python-jose[cryptography]>=3.3",
    "anthropic>=0.39",
    "pypdf>=4.2",
    "python-docx>=1.1",
    "httpx>=0.27",
    "python-multipart>=0.0.9",
]

[project.optional-dependencies]
dev = ["pytest>=8.2", "pytest-asyncio>=0.23"]

[tool.pytest.ini_options]
pythonpath = ["."]
asyncio_mode = "auto"
```

- [ ] **Step 2: Create `.env.example`**

```bash
DATABASE_URL=postgresql+psycopg://cet:cet@localhost:5432/cet
JWT_SECRET=change-me-in-prod
ANTHROPIC_API_KEY=sk-ant-xxx
GOOGLE_CLIENT_ID=xxx.apps.googleusercontent.com
APPLE_CLIENT_ID=com.example.contracttrainer
```

- [ ] **Step 3: Create `app/__init__.py` and `tests/__init__.py`** (empty files)

- [ ] **Step 4: Write the failing health test** in `tests/test_health.py`

```python
from fastapi.testclient import TestClient
from app.main import app

def test_health_ok():
    client = TestClient(app)
    resp = client.get("/health")
    assert resp.status_code == 200
    assert resp.json() == {"status": "ok"}
```

- [ ] **Step 5: Run test to verify it fails**

Run: `cd backend && python -m pytest tests/test_health.py -v`
Expected: FAIL — `ModuleNotFoundError: No module named 'app.main'`

- [ ] **Step 6: Create `app/main.py`**

```python
from fastapi import FastAPI

app = FastAPI(title="Contract English Trainer")


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}
```

- [ ] **Step 7: Install deps and run test to verify it passes**

Run: `cd backend && pip install -e ".[dev]" && python -m pytest tests/test_health.py -v`
Expected: PASS

- [ ] **Step 8: Commit**

```bash
git add backend/
git commit -m "feat(backend): scaffold FastAPI app with health endpoint"
```

---

## Task 2: Config

**Files:**
- Create: `backend/app/config.py`
- Test: `backend/tests/test_config.py`

- [ ] **Step 1: Write the failing test** in `tests/test_config.py`

```python
import os
from app.config import Settings

def test_settings_read_from_env(monkeypatch):
    monkeypatch.setenv("DATABASE_URL", "postgresql+psycopg://u:p@h:5432/d")
    monkeypatch.setenv("JWT_SECRET", "s3cret")
    monkeypatch.setenv("ANTHROPIC_API_KEY", "sk-ant-test")
    monkeypatch.setenv("GOOGLE_CLIENT_ID", "g")
    monkeypatch.setenv("APPLE_CLIENT_ID", "a")
    s = Settings()
    assert s.jwt_secret == "s3cret"
    assert s.database_url.endswith("/d")
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd backend && python -m pytest tests/test_config.py -v`
Expected: FAIL — `ModuleNotFoundError: No module named 'app.config'`

- [ ] **Step 3: Create `app/config.py`**

```python
from functools import lru_cache
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    database_url: str
    jwt_secret: str
    anthropic_api_key: str
    google_client_id: str = ""
    apple_client_id: str = ""
    jwt_algorithm: str = "HS256"
    jwt_expire_minutes: int = 60 * 24 * 30


@lru_cache
def get_settings() -> Settings:
    return Settings()
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd backend && python -m pytest tests/test_config.py -v`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add backend/app/config.py backend/tests/test_config.py
git commit -m "feat(backend): add env-driven Settings"
```

---

## Task 3: Database engine, Base, models

**Files:**
- Create: `backend/app/db.py`
- Create: `backend/app/models.py`
- Test: `backend/tests/test_models.py`

- [ ] **Step 1: Create `app/db.py`**

```python
from collections.abc import Iterator
from sqlalchemy import create_engine
from sqlalchemy.orm import DeclarativeBase, Session, sessionmaker

from app.config import get_settings


class Base(DeclarativeBase):
    pass


engine = create_engine(get_settings().database_url, future=True)
SessionLocal = sessionmaker(bind=engine, expire_on_commit=False, future=True)


def get_db() -> Iterator[Session]:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
```

- [ ] **Step 2: Write the failing test** in `tests/test_models.py`

```python
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
```

- [ ] **Step 3: Run test to verify it fails**

Run: `cd backend && python -m pytest tests/test_models.py -v`
Expected: FAIL — `ModuleNotFoundError: No module named 'app.models'`

- [ ] **Step 4: Create `app/models.py`**

```python
from datetime import datetime, timezone
from sqlalchemy import ForeignKey, String, Integer, DateTime, Text, JSON
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db import Base


def _now() -> datetime:
    return datetime.now(timezone.utc)


class User(Base):
    __tablename__ = "users"
    id: Mapped[int] = mapped_column(primary_key=True)
    email: Mapped[str] = mapped_column(String(320), unique=True, index=True)
    auth_provider: Mapped[str] = mapped_column(String(16))
    cefr_level: Mapped[str] = mapped_column(String(2), default="A1")
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=_now)

    contracts: Mapped[list["Contract"]] = relationship(back_populates="user")


class Contract(Base):
    __tablename__ = "contracts"
    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), index=True)
    title: Mapped[str] = mapped_column(String(255))
    file_url: Mapped[str] = mapped_column(String(1024))
    status: Mapped[str] = mapped_column(String(16), default="uploaded")
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=_now)

    user: Mapped["User"] = relationship(back_populates="contracts")
    clauses: Mapped[list["Clause"]] = relationship(
        back_populates="contract", order_by="Clause.order"
    )


class Clause(Base):
    __tablename__ = "clauses"
    id: Mapped[int] = mapped_column(primary_key=True)
    contract_id: Mapped[int] = mapped_column(ForeignKey("contracts.id"), index=True)
    order: Mapped[int] = mapped_column(Integer)
    original_text: Mapped[str] = mapped_column(Text)
    simple_en: Mapped[str | None] = mapped_column(Text, nullable=True)
    arabic: Mapped[str | None] = mapped_column(Text, nullable=True)
    key_terms: Mapped[list | None] = mapped_column(JSON, nullable=True)

    contract: Mapped["Contract"] = relationship(back_populates="clauses")
```

- [ ] **Step 5: Run test to verify it passes**

Run: `cd backend && python -m pytest tests/test_models.py -v`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add backend/app/db.py backend/app/models.py backend/tests/test_models.py
git commit -m "feat(backend): add db session and User/Contract/Clause models"
```

---

## Task 4: Alembic migrations

**Files:**
- Create: `backend/alembic.ini`
- Create: `backend/alembic/env.py`
- Create: `backend/alembic/versions/` (directory, keep with `.gitkeep`)

- [ ] **Step 1: Initialize Alembic**

Run: `cd backend && alembic init alembic`
Expected: creates `alembic.ini` and `alembic/` (overwrite the generated `env.py` in next step).

- [ ] **Step 2: Replace `alembic/env.py`** with a version that uses our metadata and settings

```python
from logging.config import fileConfig
from sqlalchemy import engine_from_config, pool
from alembic import context

from app.config import get_settings
from app.db import Base
import app.models  # noqa: F401  (register tables on Base.metadata)

config = context.config
config.set_main_option("sqlalchemy.url", get_settings().database_url)
if config.config_file_name is not None:
    fileConfig(config.config_file_name)

target_metadata = Base.metadata


def run_migrations_offline() -> None:
    context.configure(url=config.get_main_option("sqlalchemy.url"),
                      target_metadata=target_metadata, literal_binds=True)
    with context.begin_transaction():
        context.run_migrations()


def run_migrations_online() -> None:
    connectable = engine_from_config(
        config.get_section(config.config_ini_section, {}),
        prefix="sqlalchemy.", poolclass=pool.NullPool,
    )
    with connectable.connect() as connection:
        context.configure(connection=connection, target_metadata=target_metadata)
        with context.begin_transaction():
            context.run_migrations()


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
```

- [ ] **Step 3: Generate the initial migration**

Run: `cd backend && alembic revision --autogenerate -m "initial schema"`
Expected: a new file under `alembic/versions/` containing `create_table` for users, contracts, clauses.

- [ ] **Step 4: Apply the migration against a local Postgres**

Run: `cd backend && alembic upgrade head`
Expected: "Running upgrade -> <rev>, initial schema" with no errors. (Requires a local Postgres matching `DATABASE_URL`.)

- [ ] **Step 5: Commit**

```bash
git add backend/alembic.ini backend/alembic/
git commit -m "feat(backend): add alembic with initial schema migration"
```

---

## Task 5: Text extraction (PDF + Word)

**Files:**
- Create: `backend/app/extraction.py`
- Create: `backend/tests/fixtures/` (generated in test setup)
- Test: `backend/tests/test_extraction.py`

- [ ] **Step 1: Write the failing test** in `tests/test_extraction.py`

```python
import io
from docx import Document
from pypdf import PdfWriter
from app.extraction import extract_text, UnsupportedFileError
import pytest


def _make_docx_bytes(text: str) -> bytes:
    doc = Document()
    doc.add_paragraph(text)
    buf = io.BytesIO()
    doc.save(buf)
    return buf.getvalue()


def test_extract_docx():
    data = _make_docx_bytes("Hello clause one. Clause two follows.")
    text = extract_text(data, "contract.docx")
    assert "Hello clause one." in text


def test_extract_unknown_extension_raises():
    with pytest.raises(UnsupportedFileError):
        extract_text(b"x", "contract.txt")


def test_extract_pdf_empty_pages_ok():
    writer = PdfWriter()
    writer.add_blank_page(width=200, height=200)
    buf = io.BytesIO()
    writer.write(buf)
    text = extract_text(buf.getvalue(), "contract.pdf")
    assert isinstance(text, str)
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd backend && python -m pytest tests/test_extraction.py -v`
Expected: FAIL — `ModuleNotFoundError: No module named 'app.extraction'`

- [ ] **Step 3: Create `app/extraction.py`**

```python
import io
from pypdf import PdfReader
from docx import Document


class UnsupportedFileError(ValueError):
    pass


def extract_text(data: bytes, filename: str) -> str:
    name = filename.lower()
    if name.endswith(".pdf"):
        return _extract_pdf(data)
    if name.endswith(".docx"):
        return _extract_docx(data)
    raise UnsupportedFileError(f"Unsupported file type: {filename}")


def _extract_pdf(data: bytes) -> str:
    reader = PdfReader(io.BytesIO(data))
    parts = [(page.extract_text() or "") for page in reader.pages]
    return "\n".join(parts).strip()


def _extract_docx(data: bytes) -> str:
    doc = Document(io.BytesIO(data))
    return "\n".join(p.text for p in doc.paragraphs).strip()
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd backend && python -m pytest tests/test_extraction.py -v`
Expected: PASS (3 passed)

- [ ] **Step 5: Commit**

```bash
git add backend/app/extraction.py backend/tests/test_extraction.py
git commit -m "feat(backend): add PDF/Word text extraction"
```

---

## Task 6: Claude client wrapper (injectable)

**Files:**
- Create: `backend/app/claude_client.py`
- Test: `backend/tests/test_claude_client.py`

The wrapper exposes one method per AI task. Each returns parsed, validated JSON. A `ClaudeClient` protocol lets tests inject a fake. The real client calls the `anthropic` SDK.

- [ ] **Step 1: Write the failing test** in `tests/test_claude_client.py`

```python
import json
from app.claude_client import RealClaudeClient, BadAIResponseError
import pytest


class _FakeMessages:
    def __init__(self, payload: str):
        self._payload = payload

    def create(self, **kwargs):
        class _Block:
            text = self._payload
        class _Resp:
            content = [_Block()]
        return _Resp()


class _FakeAnthropic:
    def __init__(self, payload: str):
        self.messages = _FakeMessages(payload)


def test_complete_json_parses_object():
    payload = json.dumps({"clauses": ["a", "b"]})
    client = RealClaudeClient(sdk=_FakeAnthropic(payload), model="m", fast_model="m")
    result = client.complete_json("system", "user")
    assert result == {"clauses": ["a", "b"]}


def test_complete_json_strips_markdown_fence():
    payload = "```json\n{\"x\": 1}\n```"
    client = RealClaudeClient(sdk=_FakeAnthropic(payload), model="m", fast_model="m")
    assert client.complete_json("s", "u") == {"x": 1}


def test_complete_json_raises_on_garbage():
    client = RealClaudeClient(sdk=_FakeAnthropic("not json"), model="m", fast_model="m")
    with pytest.raises(BadAIResponseError):
        client.complete_json("s", "u")
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd backend && python -m pytest tests/test_claude_client.py -v`
Expected: FAIL — `ModuleNotFoundError: No module named 'app.claude_client'`

- [ ] **Step 3: Create `app/claude_client.py`**

```python
import json
from typing import Any, Protocol


class BadAIResponseError(ValueError):
    pass


class ClaudeClient(Protocol):
    def complete_json(self, system: str, user: str, *, fast: bool = False) -> Any: ...


def _strip_fence(text: str) -> str:
    t = text.strip()
    if t.startswith("```"):
        t = t.split("\n", 1)[1] if "\n" in t else t
        if t.endswith("```"):
            t = t[: -3]
    return t.strip()


class RealClaudeClient:
    def __init__(self, sdk: Any, model: str, fast_model: str):
        self._sdk = sdk
        self._model = model
        self._fast_model = fast_model

    def complete_json(self, system: str, user: str, *, fast: bool = False) -> Any:
        resp = self._sdk.messages.create(
            model=self._fast_model if fast else self._model,
            max_tokens=4096,
            system=system,
            messages=[{"role": "user", "content": user}],
        )
        raw = "".join(block.text for block in resp.content)
        try:
            return json.loads(_strip_fence(raw))
        except json.JSONDecodeError as exc:
            raise BadAIResponseError(f"Claude returned non-JSON: {raw[:200]}") from exc


def build_default_client() -> RealClaudeClient:
    import anthropic
    from app.config import get_settings

    settings = get_settings()
    sdk = anthropic.Anthropic(api_key=settings.anthropic_api_key)
    return RealClaudeClient(
        sdk=sdk,
        model="claude-opus-4-8",
        fast_model="claude-haiku-4-5-20251001",
    )
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd backend && python -m pytest tests/test_claude_client.py -v`
Expected: PASS (3 passed)

- [ ] **Step 5: Commit**

```bash
git add backend/app/claude_client.py backend/tests/test_claude_client.py
git commit -m "feat(backend): add injectable Claude client with JSON parsing"
```

---

## Task 7: Auth (provider verify + JWT)

**Files:**
- Create: `backend/app/auth.py`
- Test: `backend/tests/test_auth.py`

For the MVP, provider ID-token verification is abstracted behind a `verify_provider_token` function injected as a dependency, so tests can supply a fake verifier. JWT issue/decode is real and fully tested.

- [ ] **Step 1: Write the failing test** in `tests/test_auth.py`

```python
import pytest
from app.auth import create_jwt, decode_jwt, JwtError

SECRET = "test-secret"

def test_jwt_roundtrip():
    token = create_jwt(user_id=42, secret=SECRET)
    payload = decode_jwt(token, secret=SECRET)
    assert payload["sub"] == "42"

def test_jwt_wrong_secret_raises():
    token = create_jwt(user_id=1, secret=SECRET)
    with pytest.raises(JwtError):
        decode_jwt(token, secret="other")
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd backend && python -m pytest tests/test_auth.py -v`
Expected: FAIL — `ModuleNotFoundError: No module named 'app.auth'`

- [ ] **Step 3: Create `app/auth.py`**

```python
from datetime import datetime, timedelta, timezone
from jose import jwt, JWTError


class JwtError(Exception):
    pass


def create_jwt(user_id: int, secret: str, algorithm: str = "HS256",
               expire_minutes: int = 60 * 24 * 30) -> str:
    now = datetime.now(timezone.utc)
    payload = {
        "sub": str(user_id),
        "iat": int(now.timestamp()),
        "exp": int((now + timedelta(minutes=expire_minutes)).timestamp()),
    }
    return jwt.encode(payload, secret, algorithm=algorithm)


def decode_jwt(token: str, secret: str, algorithm: str = "HS256") -> dict:
    try:
        return jwt.decode(token, secret, algorithms=[algorithm])
    except JWTError as exc:
        raise JwtError(str(exc)) from exc
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd backend && python -m pytest tests/test_auth.py -v`
Expected: PASS (2 passed)

- [ ] **Step 5: Commit**

```bash
git add backend/app/auth.py backend/tests/test_auth.py
git commit -m "feat(backend): add JWT issue/decode"
```

---

## Task 8: Shared test fixtures (db, client, fake Claude)

**Files:**
- Create: `backend/tests/conftest.py`

- [ ] **Step 1: Create `tests/conftest.py`**

```python
import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.db import Base, get_db
from app.deps import get_claude, get_current_user
from app.main import app
from app.models import User


@pytest.fixture
def db_session():
    engine = create_engine("sqlite://", future=True,
                           connect_args={"check_same_thread": False})
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
```

- [ ] **Step 2: Commit** (no test run yet — `deps.py` is created in Task 9; this fixture file is imported then)

```bash
git add backend/tests/conftest.py
git commit -m "test(backend): add shared db/client/fake-claude fixtures"
```

---

## Task 9: Dependencies (db, current user, claude)

**Files:**
- Create: `backend/app/deps.py`
- Test: covered indirectly by router tests (Task 11)

- [ ] **Step 1: Create `app/deps.py`**

```python
from typing import Iterator
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.orm import Session

from app.auth import decode_jwt, JwtError
from app.claude_client import ClaudeClient, build_default_client
from app.config import get_settings
from app.db import get_db
from app.models import User

_bearer = HTTPBearer(auto_error=True)


def get_claude() -> ClaudeClient:
    return build_default_client()


def get_current_user(
    creds: HTTPAuthorizationCredentials = Depends(_bearer),
    db: Session = Depends(get_db),
) -> User:
    settings = get_settings()
    try:
        payload = decode_jwt(creds.credentials, secret=settings.jwt_secret,
                             algorithm=settings.jwt_algorithm)
    except JwtError:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Invalid token")
    user = db.get(User, int(payload["sub"]))
    if user is None:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Unknown user")
    return user
```

- [ ] **Step 2: Run the existing suite to confirm nothing breaks**

Run: `cd backend && python -m pytest -v`
Expected: all prior tests PASS (conftest now imports cleanly).

- [ ] **Step 3: Commit**

```bash
git add backend/app/deps.py
git commit -m "feat(backend): add FastAPI dependencies (db, current user, claude)"
```

---

## Task 10: Contracts service (split + explain orchestration)

**Files:**
- Create: `backend/app/services/__init__.py` (empty)
- Create: `backend/app/services/contracts.py`
- Test: `backend/tests/test_contracts_service.py`

The service takes extracted text + a Claude client + a db session and a user. It asks Claude to split the text into clauses, persists them, then asks Claude to explain each, persisting the explanation. Prompts are constants in the module.

- [ ] **Step 1: Write the failing test** in `tests/test_contracts_service.py`

```python
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
        {"clauses": ["Clause one text.", "Clause two text."]},          # split
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd backend && python -m pytest tests/test_contracts_service.py -v`
Expected: FAIL — `ModuleNotFoundError: No module named 'app.services.contracts'`

- [ ] **Step 3: Create `app/services/__init__.py`** (empty) and `app/services/contracts.py`

```python
from sqlalchemy.orm import Session

from app.claude_client import ClaudeClient
from app.models import Clause, Contract

SPLIT_SYSTEM = (
    "You split legal contracts into individual clauses for an English learner. "
    "Return JSON: {\"clauses\": [\"clause text\", ...]} preserving original wording "
    "and order. Do not summarize."
)

EXPLAIN_SYSTEM = (
    "You explain one contract clause to an Arabic-speaking English learner. "
    "Return JSON with keys: simple_en (plain-English explanation), "
    "arabic (Arabic translation of the explanation), "
    "key_terms (array of {term, meaning} for important legal words)."
)


def split_and_explain(db: Session, claude: ClaudeClient,
                      contract: Contract, full_text: str) -> None:
    split = claude.complete_json(SPLIT_SYSTEM, full_text)
    texts = split.get("clauses", [])
    contract.status = "parsed"
    db.flush()

    for index, text in enumerate(texts, start=1):
        explanation = claude.complete_json(EXPLAIN_SYSTEM, text)
        clause = Clause(
            contract_id=contract.id,
            order=index,
            original_text=text,
            simple_en=explanation.get("simple_en"),
            arabic=explanation.get("arabic"),
            key_terms=explanation.get("key_terms", []),
        )
        db.add(clause)

    contract.status = "explained"
    db.commit()
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd backend && python -m pytest tests/test_contracts_service.py -v`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add backend/app/services/
git commit -m "feat(backend): add contract split+explain service"
```

---

## Task 11: Contracts router (upload + fetch)

**Files:**
- Create: `backend/app/schemas.py`
- Create: `backend/app/routers/__init__.py` (empty)
- Create: `backend/app/routers/contracts_router.py`
- Modify: `backend/app/main.py` (wire the router)
- Test: `backend/tests/test_contracts_router.py`

For the MVP the uploaded file bytes are extracted in-process; `file_url` is set to a placeholder local marker (object-store upload is a later plan). The endpoint extracts text, creates the contract, runs split+explain, returns the contract with clauses.

- [ ] **Step 1: Create `app/schemas.py`**

```python
from pydantic import BaseModel


class KeyTerm(BaseModel):
    term: str
    meaning: str


class ClauseOut(BaseModel):
    id: int
    order: int
    original_text: str
    simple_en: str | None = None
    arabic: str | None = None
    key_terms: list[KeyTerm] = []


class ContractOut(BaseModel):
    id: int
    title: str
    status: str
    clauses: list[ClauseOut] = []

    class Config:
        from_attributes = True
```

- [ ] **Step 2: Write the failing test** in `tests/test_contracts_router.py`

```python
import io
from docx import Document


def _docx_bytes(text: str) -> bytes:
    doc = Document()
    doc.add_paragraph(text)
    buf = io.BytesIO()
    doc.save(buf)
    return buf.getvalue()


def test_upload_contract_returns_explained_clauses(client, fake_claude):
    fake_claude._responses = [
        {"clauses": ["Clause one.", "Clause two."]},
        {"simple_en": "S1", "arabic": "ع1", "key_terms": []},
        {"simple_en": "S2", "arabic": "ع2", "key_terms": []},
    ]
    files = {"file": ("c.docx", _docx_bytes("Whole contract."),
                      "application/vnd.openxmlformats-officedocument.wordprocessingml.document")}
    resp = client.post("/contracts", files=files, data={"title": "My Contract"})
    assert resp.status_code == 201
    body = resp.json()
    assert body["status"] == "explained"
    assert len(body["clauses"]) == 2
    assert body["clauses"][0]["simple_en"] == "S1"


def test_upload_unsupported_file_returns_400(client):
    files = {"file": ("c.txt", b"hi", "text/plain")}
    resp = client.post("/contracts", files=files, data={"title": "X"})
    assert resp.status_code == 400


def test_get_contract_returns_clauses(client, fake_claude):
    fake_claude._responses = [
        {"clauses": ["Only clause."]},
        {"simple_en": "S", "arabic": "ع", "key_terms": []},
    ]
    up = client.post("/contracts",
                     files={"file": ("c.docx", _docx_bytes("x"),
                            "application/vnd.openxmlformats-officedocument.wordprocessingml.document")},
                     data={"title": "T"})
    cid = up.json()["id"]
    resp = client.get(f"/contracts/{cid}")
    assert resp.status_code == 200
    assert resp.json()["clauses"][0]["simple_en"] == "S"
```

- [ ] **Step 3: Run test to verify it fails**

Run: `cd backend && python -m pytest tests/test_contracts_router.py -v`
Expected: FAIL — cannot import `app.routers.contracts_router`.

- [ ] **Step 4: Create `app/routers/__init__.py`** (empty) and `app/routers/contracts_router.py`

```python
from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile, status
from sqlalchemy.orm import Session

from app.claude_client import ClaudeClient
from app.deps import get_claude, get_current_user
from app.db import get_db
from app.extraction import extract_text, UnsupportedFileError
from app.models import Contract, User
from app.schemas import ContractOut
from app.services.contracts import split_and_explain

router = APIRouter(prefix="/contracts", tags=["contracts"])


@router.post("", response_model=ContractOut, status_code=status.HTTP_201_CREATED)
def upload_contract(
    title: str = Form(...),
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    claude: ClaudeClient = Depends(get_claude),
    user: User = Depends(get_current_user),
) -> Contract:
    data = file.file.read()
    try:
        text = extract_text(data, file.filename or "")
    except UnsupportedFileError as exc:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, str(exc))

    contract = Contract(user_id=user.id, title=title,
                        file_url=f"local://{file.filename}", status="uploaded")
    db.add(contract)
    db.commit()
    split_and_explain(db, claude, contract, text)
    db.refresh(contract)
    return contract


@router.get("/{contract_id}", response_model=ContractOut)
def get_contract(
    contract_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
) -> Contract:
    contract = db.get(Contract, contract_id)
    if contract is None or contract.user_id != user.id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Not found")
    return contract
```

- [ ] **Step 5: Wire the router in `app/main.py`** — replace the file contents

```python
from fastapi import FastAPI

from app.routers import contracts_router

app = FastAPI(title="Contract English Trainer")
app.include_router(contracts_router.router)


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}
```

- [ ] **Step 6: Run test to verify it passes**

Run: `cd backend && python -m pytest tests/test_contracts_router.py -v`
Expected: PASS (3 passed)

- [ ] **Step 7: Commit**

```bash
git add backend/app/schemas.py backend/app/routers/ backend/app/main.py backend/tests/test_contracts_router.py
git commit -m "feat(backend): add contract upload + fetch endpoints"
```

---

## Task 12: Auth router (login)

**Files:**
- Create: `backend/app/routers/auth_router.py`
- Modify: `backend/app/main.py` (wire the router)
- Modify: `backend/app/deps.py` (add injectable provider verifier)
- Test: `backend/tests/test_auth_router.py`

The login endpoint accepts `{provider, id_token}`, verifies it via an injected `verify_provider_token` dependency (real implementation calls Google/Apple; tests override it), upserts the user, and returns our JWT.

- [ ] **Step 1: Add the provider-verifier dependency to `app/deps.py`** (append)

```python
from pydantic import BaseModel


class ProviderIdentity(BaseModel):
    email: str
    provider: str


def verify_provider_token(provider: str, id_token: str) -> ProviderIdentity:
    # Real verification (Google/Apple) is wired in a later deployment task.
    # Until then this raises so it is never silently insecure in production.
    raise NotImplementedError("Provider verification not configured")
```

- [ ] **Step 2: Write the failing test** in `tests/test_auth_router.py`

```python
from app.deps import verify_provider_token, ProviderIdentity, get_db
from app.main import app
from app.models import User


def test_login_creates_user_and_returns_jwt(db_session, monkeypatch):
    from fastapi.testclient import TestClient

    app.dependency_overrides[get_db] = lambda: db_session
    app.dependency_overrides[verify_provider_token] = (
        lambda: lambda provider, id_token: ProviderIdentity(email="new@e.com", provider="google")
    )
    try:
        client = TestClient(app)
        resp = client.post("/auth/login", json={"provider": "google", "id_token": "tok"})
        assert resp.status_code == 200
        assert "access_token" in resp.json()
        assert db_session.query(User).filter_by(email="new@e.com").count() == 1
    finally:
        app.dependency_overrides.clear()
```

- [ ] **Step 3: Run test to verify it fails**

Run: `cd backend && python -m pytest tests/test_auth_router.py -v`
Expected: FAIL — cannot import `app.routers.auth_router`.

- [ ] **Step 4: Create `app/routers/auth_router.py`**

```python
from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.auth import create_jwt
from app.config import get_settings
from app.db import get_db
from app.deps import verify_provider_token, ProviderIdentity
from app.models import User

router = APIRouter(prefix="/auth", tags=["auth"])


class LoginIn(BaseModel):
    provider: str
    id_token: str


class TokenOut(BaseModel):
    access_token: str
    token_type: str = "bearer"


def _verifier():
    return verify_provider_token


@router.post("/login", response_model=TokenOut)
def login(
    body: LoginIn,
    db: Session = Depends(get_db),
    verify=Depends(_verifier),
) -> TokenOut:
    identity: ProviderIdentity = verify(body.provider, body.id_token)
    user = db.query(User).filter_by(email=identity.email).one_or_none()
    if user is None:
        user = User(email=identity.email, auth_provider=identity.provider)
        db.add(user)
        db.commit()
        db.refresh(user)
    settings = get_settings()
    token = create_jwt(user.id, settings.jwt_secret,
                       algorithm=settings.jwt_algorithm,
                       expire_minutes=settings.jwt_expire_minutes)
    return TokenOut(access_token=token)
```

- [ ] **Step 5: Wire the router in `app/main.py`** — update imports and include

```python
from fastapi import FastAPI

from app.routers import auth_router, contracts_router

app = FastAPI(title="Contract English Trainer")
app.include_router(auth_router.router)
app.include_router(contracts_router.router)


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}
```

- [ ] **Step 6: Run test to verify it passes**

Run: `cd backend && python -m pytest tests/test_auth_router.py -v`
Expected: PASS

- [ ] **Step 7: Run the full suite**

Run: `cd backend && python -m pytest -v`
Expected: all tests PASS.

- [ ] **Step 8: Commit**

```bash
git add backend/app/routers/auth_router.py backend/app/deps.py backend/app/main.py backend/tests/test_auth_router.py
git commit -m "feat(backend): add login endpoint issuing app JWT"
```

---

## Verification (end of plan)

- [ ] Run the entire suite: `cd backend && python -m pytest -v` → all green.
- [ ] Start the server locally: `cd backend && uvicorn app.main:app --reload` → open `http://localhost:8000/docs` and confirm `/health`, `/auth/login`, `POST /contracts`, `GET /contracts/{id}` appear.

---

## Self-Review Notes (author)

- **Spec coverage:** This plan implements spec §2 (architecture skeleton), §3 (users/contracts/clauses tables), §4 flows #1 (analyze & split) and #2 (explain clause), and auth from §2. Remaining spec sections — word cards (#3), quizzes (#4–5), tutor (#6), CEFR (#7), final exam/summary (#8), spaced repetition (§5), dashboard/daily plan, object-store upload, and real Google/Apple verification — are deferred to subsequent plans, as noted in the header.
- **Deferred, tracked:** object-store upload (currently `file_url=local://…`), real provider token verification (`verify_provider_token` raises until configured). Both are explicit, not silent gaps.
- **Type consistency:** `split_and_explain(db, claude, contract, full_text)` signature matches its call in the router; `ClaudeClient.complete_json(system, user, *, fast=False)` matches the fake in conftest and all call sites; `ProviderIdentity(email, provider)` matches its construction in tests and use in the auth router.
