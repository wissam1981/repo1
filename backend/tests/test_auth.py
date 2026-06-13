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
