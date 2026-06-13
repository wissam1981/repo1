"""Guest login reuses a single shared account so progress persists."""
from app.models import User


def test_guest_login_reuses_shared_account(client, db_session):
    r1 = client.post("/auth/guest")
    r2 = client.post("/auth/guest")
    assert r1.status_code == 200
    assert r2.status_code == 200
    guests = db_session.query(User).filter_by(auth_provider="guest").count()
    assert guests == 1
