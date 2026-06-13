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
