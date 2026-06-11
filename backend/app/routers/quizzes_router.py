"""Quiz endpoints: generate a quiz, submit answers, list attempt history."""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.cefr import estimate_cefr_level
from app.db import get_db
from app.deps import get_claude, get_current_user
from app.models import Clause, Contract, Quiz, QuizAttempt, User
from app.schemas import QuizAttemptOut, QuizGenerateIn, QuizOut, QuizSubmitIn
from app.services.quizzes import generate_quiz, grade_quiz_submission

router = APIRouter(prefix="/quizzes", tags=["quizzes"])


@router.post("/generate", response_model=QuizOut, status_code=status.HTTP_201_CREATED)
def create_quiz(
    body: QuizGenerateIn,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
    claude=Depends(get_claude),
):
    """Generate a quiz from a clause or contract the user owns."""
    if not body.clause_id and not body.contract_id:
        raise HTTPException(status.HTTP_422_UNPROCESSABLE_ENTITY, "clause_id or contract_id required")

    # Validate ownership (clause or contract belongs to user).
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
    claude=Depends(get_claude),
):
    """Submit answers for a quiz, grade them, and persist the attempt."""
    quiz = db.get(Quiz, body.quiz_id)
    if not quiz:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Quiz not found")

    attempt = QuizAttempt(user_id=user.id, quiz_id=quiz.id, answers=body.answers)
    db.add(attempt)
    db.flush()

    grade_quiz_submission(db, claude, attempt)
    db.commit()
    db.refresh(attempt)

    # Update the user's CEFR level based on their most recent quiz scores.
    recent_attempts = (
        db.query(QuizAttempt)
        .filter_by(user_id=user.id)
        .order_by(QuizAttempt.created_at.desc())
        .limit(10)
        .all()
    )
    scores = [a.score for a in recent_attempts]
    user.cefr_level = estimate_cefr_level(scores).value
    db.commit()

    return attempt


@router.get("/history", response_model=list[QuizAttemptOut])
def quiz_history(
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Return the current user's quiz attempts, most recent first."""
    attempts = (
        db.query(QuizAttempt)
        .filter_by(user_id=user.id)
        .order_by(QuizAttempt.created_at.desc())
        .all()
    )
    return attempts
