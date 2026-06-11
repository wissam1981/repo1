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
    words: Mapped[list["Word"]] = relationship(back_populates="user")


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
    completed_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True), nullable=True
    )
    is_definition: Mapped[bool] = mapped_column(default=False)
    # For definitions: 1-based orders of clauses that use the defined term.
    related_orders: Mapped[list | None] = mapped_column(JSON, nullable=True)

    contract: Mapped["Contract"] = relationship(back_populates="clauses")

    @property
    def completed(self) -> bool:
        return self.completed_at is not None


class Word(Base):
    __tablename__ = "words"
    id: Mapped[int] = mapped_column(primary_key=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), index=True)
    term: Mapped[str] = mapped_column(String(255), index=True)
    meaning: Mapped[str] = mapped_column(Text)
    example: Mapped[str] = mapped_column(Text)
    clause_id: Mapped[int | None] = mapped_column(ForeignKey("clauses.id"), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=_now)

    user: Mapped["User"] = relationship(back_populates="words")
    reviews: Mapped[list["Review"]] = relationship(back_populates="word")


class Review(Base):
    __tablename__ = "reviews"
    id: Mapped[int] = mapped_column(primary_key=True)
    word_id: Mapped[int] = mapped_column(ForeignKey("words.id"), index=True)
    due_date: Mapped[datetime] = mapped_column(DateTime(timezone=True), index=True)
    ease: Mapped[float]
    interval_days: Mapped[int]
    repetitions: Mapped[int]
    last_result: Mapped[int | None] = mapped_column(nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=_now)

    word: Mapped["Word"] = relationship(back_populates="reviews")


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
