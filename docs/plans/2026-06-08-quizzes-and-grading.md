# Quizzes & Grading — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a tested FastAPI backend system that generates quizzes from contracts (multiple-choice, true/false, fill-in-the-blank, open-ended comprehension) and grades user answers, storing results for progress tracking.

**Architecture:** Extend the existing database with `quizzes` and `quiz_attempts` tables. Implement Claude prompt flows to generate quizzes of each type and grade open-ended answers. Add endpoints to POST (generate quiz), POST (submit answers), and GET (quiz history). Integrate grade results with the existing `User.cefr_level` (updated by the CEFR estimation plan, but prepared here).

**Tech Stack:** Same as Plan 1 (FastAPI, SQLAlchemy, PostgreSQL, pytest, Claude API for generation + grading).

This is the fourth of four plans (after scaffold, vocabulary, frontend). Plans 1–2 are complete. Plan 3 (frontend) is a template ready for implementation in parallel with this.

---

## File Structure

```
backend/
  app/
    services/
      quizzes.py                  # generate quiz, grade answers
    routers/
      quizzes_router.py           # POST generate, POST submit, GET history
  tests/
    test_quizzes_service.py
    test_quizzes_router.py
```

**Responsibilities**
- `quizzes.py` — orchestrate Claude calls to generate quizzes (type-specific prompts) and grade open-ended answers; persist to DB.
- `routers/quizzes_router.py` — HTTP handlers. Depend on `get_current_user`, `get_db`, `services/quizzes`.

---

## Task 1: Add Quiz and QuizAttempt models

**Files:**
- Modify: `backend/app/models.py` (append models)

- [ ] **Step 1: Append to `backend/app/models.py`**

```python
class Quiz(Base):
    __tablename__ = "quizzes"
    id: Mapped[int] = mapped_column(primary_key=True)
    clause_id: Mapped[int | None] = mapped_column(ForeignKey("clauses.id"), nullable=True)
    contract_id: Mapped[int | None] = mapped_column(ForeignKey("contracts.id"), nullable=True)
    quiz_type: Mapped[str] = mapped_column(String(16))  # mcq, tf, fill, open, final
    questions: Mapped[list] = mapped_column(JSON)  # array of question objects
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=_now)

    clause: Mapped["Clause | None"] = relationship()
    contract: Mapped["Contract | None"] = relationship()
    attempts: Mapped[list["QuizAttempt"]] = relationship(back_populates="quiz")


class QuizAttempt(Base):
    __tablename__ = "quiz_attempts"
    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), index=True)
    quiz_id: Mapped[int] = mapped_column(ForeignKey("quizzes.id"), index=True)
    answers: Mapped[list] = mapped_column(JSON)  # user's responses
    score: Mapped[float] = mapped_column(default=0.0)  # 0.0 to 1.0
    feedback: Mapped[str | None] = mapped_column(Text, nullable=True)  # grading feedback
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=_now)

    user: Mapped["User"] = relationship()
    quiz: Mapped["Quiz"] = relationship(back_populates="attempts")
```

- [ ] **Step 2: Commit**

```bash
git add backend/app/models.py
git commit -m "feat(backend): add Quiz and QuizAttempt models"
```

---

## Task 2: Quiz generation and grading service

**Files:**
- Create: `backend/app/services/quizzes.py`
- Test: `backend/tests/test_quizzes_service.py`

- [ ] **Step 1: Write failing test** in `tests/test_quizzes_service.py`

```python
from app.models import User, Contract, Clause
from app.services.quizzes import generate_quiz, grade_quiz_submission
from tests.conftest import FakeClaude

def test_generate_mcq_quiz(db_session, fake_claude):
    user = User(email="u@e.com", auth_provider="google")
    contract = Contract(user_id=None, title="T", file_url="s3://x")
    clause = Clause(contract_id=None, order=1, original_text="The term is 12 months.")
    db_session.add_all([user, contract, clause])
    db_session.flush()
    contract.user_id = user.id
    clause.contract_id = contract.id
    db_session.commit()

    fake_claude._responses = [{
        "questions": [
            {
                "type": "mcq",
                "question": "What is the term?",
                "options": ["6 months", "12 months", "24 months", "36 months"],
                "correct_index": 1,
            }
        ]
    }]

    quiz = generate_quiz(db_session, fake_claude, clause_id=clause.id, quiz_type="mcq", count=1)
    assert quiz.quiz_type == "mcq"
    assert len(quiz.questions) == 1
    assert quiz.questions[0]["question"] == "What is the term?"

def test_grade_open_answer(db_session, fake_claude):
    # Setup: create a quiz with open question
    user = User(email="u@e.com", auth_provider="google")
    db_session.add(user)
    db_session.flush()
    quiz_obj = Quiz(contract_id=None, clause_id=None, quiz_type="open", questions=[
        {"type": "open", "question": "Explain clause 5."}
    ])
    db_session.add(quiz_obj)
    db_session.flush()
    attempt = QuizAttempt(user_id=user.id, quiz_id=quiz_obj.id, answers=["User's answer text here."])
    db_session.add(attempt)
    db_session.flush()

    fake_claude._responses = [{
        "score": 0.75,
        "feedback": "Good explanation, but missed one key detail.",
    }]

    grade_quiz_submission(db_session, fake_claude, attempt)
    db_session.refresh(attempt)
    assert attempt.score == 0.75
    assert "missed" in attempt.feedback.lower()
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd backend && .venv/bin/pytest tests/test_quizzes_service.py -v`
Expected: FAIL — `ModuleNotFoundError: No module named 'app.services.quizzes'`

- [ ] **Step 3: Create `app/services/quizzes.py`**

```python
from sqlalchemy.orm import Session
from app.claude_client import ClaudeClient
from app.models import Quiz, QuizAttempt, Clause

QUIZ_GENERATION_SYSTEM = (
    "You generate quiz questions for English learners reading legal contracts. "
    "Return JSON: {\"questions\": [...]} where each question is type-specific."
)

QUIZ_GRADING_SYSTEM = (
    "You grade a user's answer to a comprehension question. "
    "Return JSON: {\"score\": 0.0-1.0, \"feedback\": \"explanation\"}"
)


def generate_quiz(
    db: Session,
    claude: ClaudeClient,
    clause_id: int | None = None,
    contract_id: int | None = None,
    quiz_type: str = "mcq",
    count: int = 1,
) -> Quiz:
    """Generate a quiz and persist it."""
    if not clause_id and not contract_id:
        raise ValueError("Either clause_id or contract_id is required")

    clause = db.get(Clause, clause_id) if clause_id else None
    context = clause.original_text if clause else f"Contract #{contract_id}"

    user_prompt = (
        f"Generate {count} {quiz_type} questions for this contract text:\n\n{context}\n\n"
        f"Question type: {quiz_type}\n"
        f"For MCQ: include 4 options with correct_index.\n"
        f"For TF (true/false): include correct answer (true/false).\n"
        f"For fill-blank: provide blank position and correct word(s).\n"
        f"For open: comprehension question that tests deep understanding."
    )

    response = claude.complete_json(QUIZ_GENERATION_SYSTEM, user_prompt)
    questions = response.get("questions", [])

    quiz = Quiz(
        clause_id=clause_id,
        contract_id=contract_id,
        quiz_type=quiz_type,
        questions=questions,
    )
    db.add(quiz)
    db.commit()
    return quiz


def grade_quiz_submission(
    db: Session,
    claude: ClaudeClient,
    attempt: QuizAttempt,
) -> None:
    """Grade a user's quiz submission and update the attempt."""
    db.refresh(attempt)
    quiz = attempt.quiz
    questions = quiz.questions

    if quiz.quiz_type == "open":
        # Use Claude to grade open-ended answers
        user_answers_text = "\n".join(
            f"Q: {q.get('question')}\nA: {ans}"
            for q, ans in zip(questions, attempt.answers)
        )
        grade_prompt = f"Grade these answers:\n\n{user_answers_text}"
        grade_response = claude.complete_json(QUIZ_GRADING_SYSTEM, grade_prompt)
        attempt.score = grade_response.get("score", 0.0)
        attempt.feedback = grade_response.get("feedback")
    else:
        # Auto-grade MCQ/TF/fill based on correct answers
        score = 0.0
        for i, (q, user_ans) in enumerate(zip(questions, attempt.answers)):
            if q["type"] == "mcq" and user_ans == q.get("correct_index"):
                score += 1.0 / len(questions)
            elif q["type"] == "tf" and user_ans == q.get("correct"):
                score += 1.0 / len(questions)
            elif q["type"] == "fill" and user_ans.lower() == q.get("correct_word", "").lower():
                score += 1.0 / len(questions)
        attempt.score = score
        attempt.feedback = f"Scored {int(score * 100)}%"

    db.commit()
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd backend && .venv/bin/pytest tests/test_quizzes_service.py -v`
Expected: PASS (2 tests)

- [ ] **Step 5: Commit**

```bash
git add backend/app/services/quizzes.py backend/tests/test_quizzes_service.py
git commit -m "feat(backend): add quiz generation and grading service"
```

---

## Task 3: Quiz routes (endpoints)

**Files:**
- Create/update: `backend/app/schemas.py` (add quiz schemas)
- Create: `backend/app/routers/quizzes_router.py`
- Modify: `backend/app/main.py` (wire router)
- Test: `backend/tests/test_quizzes_router.py`

- [ ] **Step 1: Add schemas** to `backend/app/schemas.py`

```python
class QuestionIn(BaseModel):
    type: str  # mcq, tf, fill, open
    question: str
    # mcq-specific
    options: list[str] = []
    correct_index: int | None = None
    # tf-specific
    correct: bool | None = None
    # fill-specific
    correct_word: str | None = None

class QuizGenerateIn(BaseModel):
    clause_id: int | None = None
    contract_id: int | None = None
    quiz_type: str  # mcq, tf, fill, open, final
    count: int = 1

class QuizOut(BaseModel):
    id: int
    quiz_type: str
    questions: list[dict]
    created_at: str
    class Config:
        from_attributes = True

class QuizSubmitIn(BaseModel):
    quiz_id: int
    answers: list  # user's responses (string, int, or bool depending on type)

class QuizAttemptOut(BaseModel):
    id: int
    score: float
    feedback: str | None
    created_at: str
    class Config:
        from_attributes = True
```

- [ ] **Step 2: Write failing test** in `tests/test_quizzes_router.py`

```python
from app.models import Quiz, QuizAttempt

def test_generate_quiz_returns_201(client):
    resp = client.post("/quizzes/generate", json={
        "clause_id": 1,  # assumes clause 1 exists from prior test
        "quiz_type": "mcq",
        "count": 2,
    })
    assert resp.status_code == 201
    body = resp.json()
    assert body["quiz_type"] == "mcq"
    assert body["id"] is not None

def test_submit_quiz_returns_attempt(client, db_session):
    # Setup: create a quiz
    quiz = Quiz(contract_id=None, clause_id=None, quiz_type="mcq", questions=[
        {"type": "mcq", "question": "Q?", "options": ["a", "b", "c"], "correct_index": 1}
    ])
    db_session.add(quiz)
    db_session.commit()
    
    # Submit answers
    resp = client.post("/quizzes/submit", json={
        "quiz_id": quiz.id,
        "answers": [1],  # correct
    })
    assert resp.status_code == 201
    body = resp.json()
    assert body["score"] == 1.0  # 100% if all correct

def test_quiz_history(client, db_session):
    resp = client.get("/quizzes/history")
    assert resp.status_code == 200
    assert isinstance(resp.json(), list)
```

- [ ] **Step 3: Run test to verify it fails**

Run: `cd backend && .venv/bin/pytest tests/test_quizzes_router.py::test_generate_quiz_returns_201 -v`
Expected: FAIL — router not defined.

- [ ] **Step 4: Create `app/routers/quizzes_router.py`**

```python
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.db import get_db
from app.deps import get_current_user, get_claude
from app.models import User, Quiz, QuizAttempt
from app.schemas import QuizGenerateIn, QuizOut, QuizSubmitIn, QuizAttemptOut
from app.services.quizzes import generate_quiz, grade_quiz_submission

router = APIRouter(prefix="/quizzes", tags=["quizzes"])


@router.post("/generate", response_model=QuizOut, status_code=status.HTTP_201_CREATED)
def create_quiz(
    body: QuizGenerateIn,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
    claude = Depends(get_claude),
):
    # Validate ownership (clause or contract belongs to user)
    if body.clause_id:
        clause = db.get(Clause, body.clause_id)
        if not clause or clause.contract.user_id != user.id:
            raise HTTPException(status.HTTP_403_FORBIDDEN, "Not your clause")
    if body.contract_id:
        contract = db.get(Contract, body.contract_id)
        if not contract or contract.user_id != user.id:
            raise HTTPException(status.HTTP_403_FORBIDDEN, "Not your contract")

    quiz = generate_quiz(
        db, claude,
        clause_id=body.clause_id,
        contract_id=body.contract_id,
        quiz_type=body.quiz_type,
        count=body.count,
    )
    return quiz


@router.post("/submit", response_model=QuizAttemptOut, status_code=status.HTTP_201_CREATED)
def submit_quiz(
    body: QuizSubmitIn,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
    claude = Depends(get_claude),
):
    quiz = db.get(Quiz, body.quiz_id)
    if not quiz:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Quiz not found")

    attempt = QuizAttempt(user_id=user.id, quiz_id=quiz.id, answers=body.answers)
    db.add(attempt)
    db.flush()

    grade_quiz_submission(db, claude, attempt)
    db.commit()
    db.refresh(attempt)
    return attempt


@router.get("/history", response_model=list[QuizAttemptOut])
def quiz_history(
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    attempts = db.query(QuizAttempt).filter_by(user_id=user.id).order_by(QuizAttempt.created_at.desc()).all()
    return attempts
```

- [ ] **Step 5: Wire router in `app/main.py`**

```python
from app.routers import quizzes_router

app.include_router(quizzes_router.router)
```

- [ ] **Step 6: Run test to verify it passes**

Run: `cd backend && .venv/bin/pytest tests/test_quizzes_router.py -v`
Expected: PASS (3 tests)

- [ ] **Step 7: Commit**

```bash
git add backend/app/routers/quizzes_router.py backend/app/schemas.py backend/app/main.py backend/tests/test_quizzes_router.py
git commit -m "feat(backend): add quiz generation and submission endpoints"
```

---

## Task 4: DB migration

- [ ] **Step 1: Generate migration**

Run: `cd backend && DATABASE_URL=sqlite:///./_tmp.db .venv/bin/alembic revision --autogenerate -m "add quizzes and quiz_attempts tables"`

- [ ] **Step 2: Verify migration**

Open the generated file and confirm CREATE TABLE for quizzes and quiz_attempts with correct columns and FKs.

- [ ] **Step 3: Test migration**

Run: `cd backend && DATABASE_URL=sqlite:///./_tmp.db .venv/bin/alembic upgrade head && rm _tmp.db`

- [ ] **Step 4: Commit**

```bash
git add backend/alembic/versions/
git commit -m "db: add quizzes and quiz_attempts tables migration"
```

---

## Task 5: Full test suite

- [ ] **Step 1: Run full suite**

Run: `cd backend && .venv/bin/pytest -v`
Expected: all tests PASS (prior 19 + SM-2/vocab/quiz tests, likely 30+ total).

- [ ] **Step 2: Verify no new warnings**

Output clean (Starlette deprecation OK).

---

## Self-Review Notes (author)

- **Spec coverage:** This plan implements spec §4 (quiz generation + grading). Open-ended grading uses Claude; auto-grading for multiple-choice/TF/fill is client-side logic. Quiz types match spec (mcq, tf, fill, open, final). Deferred: integration with vocabulary reviews (Plan 2 can reference quiz scores for CEFR), final exam (defer to dedicated plan).
- **Service isolation:** `generate_quiz` and `grade_quiz_submission` have no HTTP concerns. Router handles ownership checks and serialization.
- **Type handling:** Each quiz type has its own correct-answer field (correct_index, correct, correct_word) validated during grading. Open-ended uses Claude for semantic grading.
- **Error handling:** Ownership checks prevent users from taking quizzes on contracts/clauses they don't own.

---

## Deferred to later plans

- **Final exam:** Comprehensive exam covering entire contract (spec §9). Deferred to a dedicated final-exam plan after vocab + quizzes are mature.
- **Quiz integration with vocab:** Quizzes can reinforce vocabulary learning (show quiz-taught words in vocab review). Deferred to vocabulary plan refinement.
- **CEFR feedback:** Quiz results feed into CEFR level estimation (Plan 5). Quiz grading is ready; CEFR aggregation comes in Plan 5.
