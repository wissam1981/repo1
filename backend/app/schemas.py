from datetime import datetime

from pydantic import BaseModel, ConfigDict


class KeyTerm(BaseModel):
    term: str
    meaning: str


class ClauseOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    order: int
    original_text: str
    simple_en: str | None = None
    arabic: str | None = None
    key_terms: list[KeyTerm] = []
    completed: bool = False
    is_definition: bool = False
    related_orders: list[int] | None = None


class ContractOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    title: str
    status: str
    clauses: list[ClauseOut] = []


# ── Vocabulary schemas ────────────────────────────────────────────────────────

class WordIn(BaseModel):
    term: str
    meaning: str
    example: str
    clause_id: int | None = None


class WordOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    term: str
    meaning: str
    example: str


class ReviewOutcome(BaseModel):
    review_id: int
    quality: int  # 0–5: 0=complete blackout, 5=perfect


class TapIn(BaseModel):
    term: str
    clause_id: int | None = None


class TapOut(BaseModel):
    word_id: int
    term: str
    meaning: str
    example: str
    meaning_en: str | None = None
    meaning_ar: str | None = None


# ── Quiz schemas ──────────────────────────────────────────────────────────────

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
    model_config = ConfigDict(from_attributes=True)

    id: int
    quiz_type: str
    questions: list[dict]
    created_at: datetime


class QuizSubmitIn(BaseModel):
    quiz_id: int
    answers: list  # user's responses (string, int, or bool depending on type)


class QuizAttemptOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    score: float
    feedback: str | None
    created_at: datetime


class TutorMessageIn(BaseModel):
    # session_id is taken from the URL path; kept here (optional) only for
    # backward compatibility with clients that still send it in the body.
    session_id: int | None = None
    message: str


class TutorMessageOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    user_id: int
    contract_id: int
    messages: list[dict]
    difficulty: int
    created_at: datetime
