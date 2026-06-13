"""Tutor endpoints: create a session, send a message, list/get sessions."""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.db import get_db
from app.deps import get_claude, get_current_user
from app.models import Contract, TutorSession, User
from app.schemas import TutorMessageIn, TutorMessageOut
from app.services.tutor import add_message, create_session, get_tutor_response

router = APIRouter(prefix="/tutor", tags=["tutor"])


@router.post(
    "/sessions/{contract_id}",
    response_model=TutorMessageOut,
    status_code=status.HTTP_201_CREATED,
)
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
    claude=Depends(get_claude),
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
    sessions = (
        db.query(TutorSession)
        .filter_by(user_id=user.id)
        .order_by(TutorSession.created_at.desc())
        .all()
    )
    return sessions
