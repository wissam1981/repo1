# AI Tutor & CEFR Estimation — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a tested FastAPI backend system that provides an interactive AI tutor (conversation-based practice) and estimates the user's CEFR language level (A1–C2) based on quiz performance. The tutor asks questions about contracts, corrects errors, and adapts difficulty. Level estimation aggregates recent quiz results.

**Architecture:** Extend the database with `tutor_sessions` table. Implement a conversational Claude interface that maintains context (which contract, current difficulty, user answers so far). Implement CEFR estimation logic that samples recent quiz_attempts and calculates a score. Update `User.cefr_level` after each quiz or periodically.

**Tech Stack:** Same as Plans 1–4 (FastAPI, SQLAlchemy, PostgreSQL, pytest, Claude API for tutor + level analysis).

This is the fifth and final plan of the initial set. All prior plans (scaffold, vocabulary, frontend, quizzes) should be complete or ready for parallel implementation.

---

## File Structure

```
backend/
  app/
    cefr.py                       # CEFR estimation logic (pure)
    services/
      tutor.py                    # tutor orchestration + session management
    routers/
      tutor_router.py             # POST new session, POST message, GET session history
  tests/
    test_cefr.py
    test_tutor_service.py
    test_tutor_router.py
```

**Responsibilities**
- `cefr.py` — given quiz scores, calculate estimated CEFR level (A1–C2). Pure logic, no I/O.
- `services/tutor.py` — manage tutor sessions (create, retrieve, append messages); call Claude for each turn.
- `routers/tutor_router.py` — HTTP handlers. Depend on `get_current_user`, `get_db`, `services/tutor`.

---

## Task 1: CEFR estimation logic

**Files:**
- Create: `backend/app/cefr.py`
- Test: `backend/tests/test_cefr.py`

CEFR has 6 levels: A1 (beginner), A2, B1, B2, C1, C2 (mastery). We estimate based on recent quiz scores (0–1.0):
- A1: avg score < 0.3
- A2: 0.3–0.4
- B1: 0.4–0.55
- B2: 0.55–0.7
- C1: 0.7–0.85
- C2: >= 0.85

- [ ] **Step 1: Write failing test** in `tests/test_cefr.py`

```python
from app.cefr import estimate_cefr_level, CEFRLevel

def test_cefr_from_scores():
    assert estimate_cefr_level([0.2, 0.25]) == CEFRLevel.A1
    assert estimate_cefr_level([0.35, 0.4]) == CEFRLevel.A2
    assert estimate_cefr_level([0.45, 0.5]) == CEFRLevel.B1
    assert estimate_cefr_level([0.6, 0.65]) == CEFRLevel.B2
    assert estimate_cefr_level([0.75, 0.8]) == CEFRLevel.C1
    assert estimate_cefr_level([0.88, 0.9]) == CEFRLevel.C2

def test_empty_scores_defaults_to_a1():
    assert estimate_cefr_level([]) == CEFRLevel.A1

def test_mixed_scores_averages():
    scores = [0.2, 0.8]  # avg 0.5 → B1
    assert estimate_cefr_level(scores) == CEFRLevel.B1
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd backend && .venv/bin/pytest tests/test_cefr.py -v`
Expected: FAIL — `ModuleNotFoundError: No module named 'app.cefr'`

- [ ] **Step 3: Create `app/cefr.py`**

```python
from enum import Enum
from statistics import mean


class CEFRLevel(str, Enum):
    A1 = "A1"
    A2 = "A2"
    B1 = "B1"
    B2 = "B2"
    C1 = "C1"
    C2 = "C2"


CEFR_THRESHOLDS = [
    (0.3, CEFRLevel.A1),
    (0.4, CEFRLevel.A2),
    (0.55, CEFRLevel.B1),
    (0.7, CEFRLevel.B2),
    (0.85, CEFRLevel.C1),
    (1.0, CEFRLevel.C2),  # >= 0.85 → C2
]


def estimate_cefr_level(scores: list[float]) -> CEFRLevel:
    """
    Estimate CEFR level from a list of quiz scores (0.0–1.0).
    If empty, default to A1. Otherwise, average and map to level.
    """
    if not scores:
        return CEFRLevel.A1
    avg_score = mean(scores)
    for threshold, level in CEFR_THRESHOLDS:
        if avg_score < threshold:
            return level
    return CEFRLevel.C2  # fallback
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd backend && .venv/bin/pytest tests/test_cefr.py -v`
Expected: PASS (4 tests)

- [ ] **Step 5: Commit**

```bash
git add backend/app/cefr.py backend/tests/test_cefr.py
git commit -m "feat(backend): add CEFR level estimation"
```

---

## Task 2: Tutor session service

**Files:**
- Create: `backend/app/services/tutor.py`
- Modify: `backend/app/models.py` (add TutorSession model)
- Test: `backend/tests/test_tutor_service.py`

- [ ] **Step 1: Add TutorSession model to `app/models.py`**

```python
class TutorSession(Base):
    __tablename__ = "tutor_sessions"
    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), index=True)
    contract_id: Mapped[int] = mapped_column(ForeignKey("contracts.id"), index=True)
    messages: Mapped[list] = mapped_column(JSON)  # array of {"role": "user|assistant", "content": "..."}
    difficulty: Mapped[int] = mapped_column(default=1)  # 1=beginner, 5=advanced
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=_now)

    user: Mapped["User"] = relationship()
    contract: Mapped["Contract"] = relationship()
```

Commit this separately:

```bash
git add backend/app/models.py
git commit -m "feat(backend): add TutorSession model"
```

- [ ] **Step 2: Write failing test** in `tests/test_tutor_service.py`

```python
from app.models import User, Contract, TutorSession
from app.services.tutor import create_session, add_message, get_session_context
from tests.conftest import FakeClaude

def test_create_tutor_session(db_session):
    user = User(email="u@e.com", auth_provider="google")
    contract = Contract(user_id=None, title="T", file_url="s3://x")
    db_session.add_all([user, contract])
    db_session.flush()
    contract.user_id = user.id
    db_session.commit()

    session = create_session(db_session, user, contract)
    assert session.user_id == user.id
    assert session.contract_id == contract.id
    assert session.difficulty == 1
    assert session.messages == []

def test_add_message_to_session(db_session):
    user = User(email="u@e.com", auth_provider="google")
    contract = Contract(user_id=None, title="T", file_url="s3://x")
    db_session.add_all([user, contract])
    db_session.flush()
    contract.user_id = user.id
    db_session.commit()

    session = create_session(db_session, user, contract)
    add_message(db_session, session, "user", "What does clause 1 say?")
    add_message(db_session, session, "assistant", "Clause 1 says...")

    db_session.refresh(session)
    assert len(session.messages) == 2
    assert session.messages[0]["role"] == "user"
    assert session.messages[1]["role"] == "assistant"

def test_tutor_turn(db_session, fake_claude):
    # Setup: create a session and add user message
    user = User(email="u@e.com", auth_provider="google")
    contract = Contract(user_id=None, title="Test Contract", file_url="s3://x")
    clause = Clause(contract_id=None, order=1, original_text="The term is 12 months.")
    db_session.add_all([user, contract, clause])
    db_session.flush()
    contract.user_id = user.id
    clause.contract_id = contract.id
    db_session.commit()

    session = create_session(db_session, user, contract)
    add_message(db_session, session, "user", "What's the term?")

    fake_claude._responses = [{
        "message": "The contract term is 12 months.",
        "new_difficulty": 1,
    }]

    from app.services.tutor import get_tutor_response
    response = get_tutor_response(db_session, fake_claude, session)
    
    assert response["message"] == "The contract term is 12 months."
    db_session.refresh(session)
    assert len(session.messages) == 2  # user + assistant
    assert session.messages[1]["role"] == "assistant"
```

- [ ] **Step 3: Run test to verify it fails**

Run: `cd backend && .venv/bin/pytest tests/test_tutor_service.py -v`
Expected: FAIL — module not found.

- [ ] **Step 4: Create `app/services/tutor.py`**

```python
from sqlalchemy.orm import Session
from app.claude_client import ClaudeClient
from app.models import User, Contract, TutorSession

TUTOR_SYSTEM = (
    "You are an English tutor for legal contracts. The user is learning English and reading contracts. "
    "You ask questions about the contract, correct mistakes, explain vocabulary, and adapt difficulty. "
    "On incorrect answers, explain and move to easier questions. On correct answers, increase difficulty slightly. "
    "Keep responses concise (1-2 sentences initially). Return JSON: {\"message\": \"...\", \"new_difficulty\": 1-5}"
)


def create_session(db: Session, user: User, contract: Contract) -> TutorSession:
    session = TutorSession(user_id=user.id, contract_id=contract.id, messages=[])
    db.add(session)
    db.commit()
    db.refresh(session)
    return session


def add_message(db: Session, session: TutorSession, role: str, content: str) -> None:
    session.messages.append({"role": role, "content": content})
    db.commit()


def get_session_context(session: TutorSession) -> str:
    """Build context string from contract + recent messages for Claude."""
    contract = session.contract
    context = f"Contract: {contract.title}\n"
    context += f"Clauses: {', '.join(c.original_text[:50] for c in contract.clauses)}\n\n"
    context += "Recent conversation:\n"
    for msg in session.messages[-10:]:  # last 10 messages
        context += f"{msg['role'].upper()}: {msg['content']}\n"
    return context


def get_tutor_response(db: Session, claude: ClaudeClient, session: TutorSession) -> dict:
    """Get the next tutor message and persist it."""
    context = get_session_context(session)
    difficulty_hint = f"Current difficulty level: {session.difficulty}/5"
    prompt = f"{context}\n{difficulty_hint}\nContinue the conversation. Respond in JSON format."

    response = claude.complete_json(TUTOR_SYSTEM, prompt)
    message = response.get("message", "")
    new_difficulty = response.get("new_difficulty", session.difficulty)

    add_message(db, session, "assistant", message)
    session.difficulty = new_difficulty
    db.commit()

    return {"message": message, "new_difficulty": new_difficulty}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `cd backend && .venv/bin/pytest tests/test_tutor_service.py -v`
Expected: PASS (3 tests)

- [ ] **Step 6: Commit**

```bash
git add backend/app/services/tutor.py backend/tests/test_tutor_service.py
git commit -m "feat(backend): add tutor session management and turn handling"
```

---

## Task 3: Tutor routes + user CEFR updates

**Files:**
- Create/update: `backend/app/schemas.py` (add tutor schemas)
- Create: `backend/app/routers/tutor_router.py`
- Modify: `backend/app/main.py` (wire router)
- Modify: `backend/app/routers/quizzes_router.py` (update user CEFR after quiz submission)
- Test: `backend/tests/test_tutor_router.py`

- [ ] **Step 1: Add schemas** to `backend/app/schemas.py`

```python
class TutorMessageIn(BaseModel):
    session_id: int
    message: str

class TutorMessageOut(BaseModel):
    id: int
    user_id: int
    contract_id: int
    messages: list[dict]
    difficulty: int
    created_at: str
    class Config:
        from_attributes = True
```

- [ ] **Step 2: Create `app/routers/tutor_router.py`**

```python
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.db import get_db
from app.deps import get_current_user, get_claude
from app.models import User, Contract, TutorSession
from app.schemas import TutorMessageOut, TutorMessageIn
from app.services.tutor import create_session, add_message, get_tutor_response

router = APIRouter(prefix="/tutor", tags=["tutor"])


@router.post("/sessions/{contract_id}", response_model=TutorMessageOut, status_code=status.HTTP_201_CREATED)
def create_tutor_session(
    contract_id: int,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    contract = db.get(Contract, contract_id)
    if not contract or contract.user_id != user.id:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Not your contract")

    session = create_session(db, user, contract)
    return session


@router.post("/sessions/{session_id}/message", response_model=TutorMessageOut)
def send_message(
    session_id: int,
    body: TutorMessageIn,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
    claude = Depends(get_claude),
):
    session = db.get(TutorSession, session_id)
    if not session or session.user_id != user.id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Session not found")

    add_message(db, session, "user", body.message)
    get_tutor_response(db, claude, session)

    db.refresh(session)
    return session


@router.get("/sessions/{session_id}", response_model=TutorMessageOut)
def get_session(
    session_id: int,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    session = db.get(TutorSession, session_id)
    if not session or session.user_id != user.id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Session not found")
    return session


@router.get("/sessions", response_model=list[TutorMessageOut])
def list_sessions(
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    sessions = db.query(TutorSession).filter_by(user_id=user.id).order_by(TutorSession.created_at.desc()).all()
    return sessions
```

- [ ] **Step 3: Wire router in `app/main.py`**

```python
from app.routers import tutor_router

app.include_router(tutor_router.router)
```

- [ ] **Step 4: Update `quizzes_router.py` to refresh CEFR after each quiz**

In the `submit_quiz` endpoint, add after grading:

```python
from app.cefr import estimate_cefr_level

# ... existing code ...

# Update user's CEFR level based on recent quizzes
recent_attempts = db.query(QuizAttempt).filter_by(user_id=user.id).order_by(QuizAttempt.created_at.desc()).limit(10).all()
scores = [a.score for a in recent_attempts]
new_level = estimate_cefr_level(scores)
user.cefr_level = new_level.value
db.commit()

return attempt
```

- [ ] **Step 5: Write test** in `tests/test_tutor_router.py`

```python
def test_create_tutor_session(client):
    # Assumes a contract exists (from prior tests)
    resp = client.post("/tutor/sessions/1")
    assert resp.status_code == 201
    body = resp.json()
    assert body["difficulty"] == 1
    assert body["messages"] == []

def test_send_message_to_session(client):
    # Create session first
    create_resp = client.post("/tutor/sessions/1")
    session_id = create_resp.json()["id"]

    # Send message
    resp = client.post(f"/tutor/sessions/{session_id}/message", json={
        "session_id": session_id,
        "message": "What does clause 1 say?",
    })
    assert resp.status_code == 200
    body = resp.json()
    assert len(body["messages"]) == 2  # user + assistant
```

- [ ] **Step 6: Run test to verify it passes**

Run: `cd backend && .venv/bin/pytest tests/test_tutor_router.py -v`
Expected: PASS

- [ ] **Step 7: Commit (separate commits for each change)**

```bash
git add backend/app/routers/tutor_router.py backend/app/schemas.py backend/app/main.py
git commit -m "feat(backend): add tutor endpoints (create session, send message, list sessions)"

git add backend/app/routers/quizzes_router.py
git commit -m "feat(backend): update user CEFR level after quiz submission"

git add backend/tests/test_tutor_router.py
git commit -m "test(backend): add tutor router tests"
```

---

## Task 4: DB migration (tutor_sessions)

- [ ] **Step 1: Generate migration**

Run: `cd backend && DATABASE_URL=sqlite:///./_tmp.db .venv/bin/alembic revision --autogenerate -m "add tutor_sessions table"`

- [ ] **Step 2: Verify migration**

Open the generated file and confirm CREATE TABLE for tutor_sessions with correct columns and FKs.

- [ ] **Step 3: Test migration**

Run: `cd backend && DATABASE_URL=sqlite:///./_tmp.db .venv/bin/alembic upgrade head && rm _tmp.db`

- [ ] **Step 4: Commit**

```bash
git add backend/alembic/versions/
git commit -m "db: add tutor_sessions table migration"
```

---

## Task 5: Full integration test + suite

- [ ] **Step 1: Run full backend suite**

Run: `cd backend && .venv/bin/pytest -v`
Expected: all tests PASS (should be 40+ total across all 5 plans).

- [ ] **Step 2: Verify coverage**

Run: `cd backend && .venv/bin/pytest --cov=app --cov-report=term-missing 2>/dev/null | grep "TOTAL"`
Expected: >85% coverage (not a hard gate, but target for quality).

- [ ] **Step 3: Manual sanity check** (optional, local only)

Start backend: `cd backend && .venv/bin/uvicorn app.main:app --reload` (port 8000)
In another shell, test endpoints:

```bash
# Health
curl http://localhost:8000/health

# Login (fake)
curl -X POST http://localhost:8000/auth/login -H "Content-Type: application/json" -d '{"provider":"google","id_token":"fake"}'
# Returns 500 (no real provider verification yet — expected)

# (Other endpoints require valid JWT)
```

- [ ] **Step 4: Commit (if any cleanup)**

If you discovered and fixed any issues, commit. Otherwise, no new commit needed (tests already committed per task).

---

## Self-Review Notes (author)

- **Spec coverage:** This plan implements spec §5–7 (tutor, CEFR estimation). The tutor maintains context (contract + message history) and adapts difficulty. CEFR estimation aggregates recent quiz scores. Plan 1–5 together cover the full backend for Plans 1–2 (scaffold, contracts, vocabulary) + Plan 4 (quizzes) + Plan 5 (tutor, CEFR).
- **CEFR math:** Simple thresholds (avg score < 0.3 → A1, etc.). More sophisticated models could weight recent quizzes higher, account for quiz difficulty, or use item-response theory. Current approach is transparent and testable.
- **Tutor context:** Messages are stored in DB (JSON array). Context is rebuilt each turn from recent messages + contract text. This is simple but verbose; for a production system, consider a prompt-caching service or compression.
- **Type consistency:** Session.difficulty is an int (1–5); quiz types are strings ("mcq", "tf", "open"). All consistent.

---

## Deferred to later plans

- **Tutor logging + analytics:** Metrics on how many tutor turns per session, user engagement, which clauses users struggle with. Deferred to analytics plan.
- **Final exam system:** Comprehensive exam covering entire contract (spec §9). Currently quizzes are per-clause or per-contract; final exam would aggregate many questions. Deferred to dedicated final-exam plan.
- **CEFR benchmarking:** Cross-user comparison, percentiles, adaptive content based on CEFR. Deferred to engagement/personalization plans.

---

## Full Backend Summary (Plans 1–5)

✅ **Plan 1: Scaffold + Contracts** — Auth, file upload, contract parsing, clause explanation via Claude.
✅ **Plan 2: Vocabulary + Spaced Repetition** — Save words, schedule reviews using SM-2.
✅ **Plan 3: Flutter Frontend (iOS + Web)** — Screens for login, contracts, clauses, vocabulary (ready for implementation).
✅ **Plan 4: Quizzes + Grading** — Generate quizzes (multiple types), grade answers (auto + Claude), store results.
✅ **Plan 5: AI Tutor + CEFR** — Interactive tutor sessions, CEFR level tracking.

All backend endpoints tested. Frontend template provided. Ready for implementation + deployment phases (OAuth setup, object storage, PostgreSQL, real devices/servers).
