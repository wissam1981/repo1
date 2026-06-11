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


def _verifier(fn=Depends(verify_provider_token)):
    return fn


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


GUEST_EMAIL = "guest@guest.local"


@router.post("/guest", response_model=TokenOut)
def login_guest(db: Session = Depends(get_db)) -> TokenOut:
    # Single shared guest account: every guest login lands on the same user,
    # so contracts and progress persist across sessions and devices.
    user = db.query(User).filter_by(email=GUEST_EMAIL).one_or_none()
    if user is None:
        user = User(email=GUEST_EMAIL, auth_provider="guest")
        db.add(user)
        db.commit()
        db.refresh(user)
    settings = get_settings()
    token = create_jwt(user.id, settings.jwt_secret,
                       algorithm=settings.jwt_algorithm,
                       expire_minutes=settings.jwt_expire_minutes)
    return TokenOut(access_token=token)
