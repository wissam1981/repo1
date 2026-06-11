from app.config import Settings

def test_settings_read_from_env(monkeypatch):
    monkeypatch.setenv("DATABASE_URL", "postgresql+psycopg://u:p@h:5432/d")
    monkeypatch.setenv("JWT_SECRET", "s3cret")
    monkeypatch.setenv("ANTHROPIC_API_KEY", "sk-ant-test")
    monkeypatch.setenv("GOOGLE_CLIENT_ID", "g")
    monkeypatch.setenv("APPLE_CLIENT_ID", "a")
    s = Settings()
    assert s.jwt_secret == "s3cret"
    assert s.database_url.endswith("/d")
