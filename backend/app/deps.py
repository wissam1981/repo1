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
    """Return the configured AI client (Claude or GPT).

    Selected via the AI_PROVIDER env var ("anthropic" or "openai"). Both
    clients expose the same complete_json() interface.
    """
    settings = get_settings()
    if settings.ai_provider.lower() == "openai":
        from app.openai_client import build_openai_client
        return build_openai_client()
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


from pydantic import BaseModel


class ProviderIdentity(BaseModel):
    email: str
    provider: str


def verify_provider_token(provider: str, id_token: str) -> ProviderIdentity:
    # Real verification (Google/Apple) is wired in a later deployment task.
    # Until then this raises so it is never silently insecure in production.
    raise NotImplementedError("Provider verification not configured")
