from app.deps import verify_provider_token, ProviderIdentity, get_db
from app.main import app
from app.models import User


def test_login_creates_user_and_returns_jwt(db_session):
    from fastapi.testclient import TestClient

    app.dependency_overrides[get_db] = lambda: db_session
    app.dependency_overrides[verify_provider_token] = (
        lambda: lambda provider, id_token: ProviderIdentity(email="new@e.com", provider="google")
    )
    try:
        client = TestClient(app)
        resp = client.post("/auth/login", json={"provider": "google", "id_token": "tok"})
        assert resp.status_code == 200
        assert "access_token" in resp.json()
        assert db_session.query(User).filter_by(email="new@e.com").count() == 1
    finally:
        app.dependency_overrides.clear()
