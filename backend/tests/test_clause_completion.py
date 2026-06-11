"""Tests for clause completion tracking (journey progress)."""
import io

from docx import Document

from app.models import Clause, Contract, User


def _docx_bytes(text: str) -> bytes:
    doc = Document()
    doc.add_paragraph(text)
    buf = io.BytesIO()
    doc.save(buf)
    return buf.getvalue()


def _make_contract(client, fake_claude):
    fake_claude._responses = [
        {"clauses": ["The term of this Agreement is twelve (12) months.",
                     "Either party may terminate with sixty (60) days notice."]},
        {"simple_en": "S1", "arabic": "ع1", "key_terms": []},
        {"simple_en": "S2", "arabic": "ع2", "key_terms": []},
    ]
    files = {"file": ("c.docx", _docx_bytes("Whole contract."),
                      "application/vnd.openxmlformats-officedocument.wordprocessingml.document")}
    resp = client.post("/contracts", files=files, data={"title": "T"})
    assert resp.status_code == 201
    # Upload is async now; fetch the processed contract (TestClient runs the
    # background task before returning).
    return client.get(f"/contracts/{resp.json()['id']}").json()


def test_clauses_start_incomplete(client, fake_claude):
    body = _make_contract(client, fake_claude)
    assert all(c["completed"] is False for c in body["clauses"])


def test_complete_clause_marks_it(client, fake_claude):
    body = _make_contract(client, fake_claude)
    cid, clause_id = body["id"], body["clauses"][0]["id"]

    resp = client.post(f"/contracts/{cid}/clauses/{clause_id}/complete")
    assert resp.status_code == 200
    assert resp.json()["completed"] is True

    # Persisted: re-fetching the contract shows it complete.
    again = client.get(f"/contracts/{cid}").json()
    flags = {c["id"]: c["completed"] for c in again["clauses"]}
    assert flags[clause_id] is True
    other = body["clauses"][1]["id"]
    assert flags[other] is False


def test_complete_unknown_clause_404(client, fake_claude):
    body = _make_contract(client, fake_claude)
    resp = client.post(f"/contracts/{body['id']}/clauses/999999/complete")
    assert resp.status_code == 404


def test_complete_clause_of_foreign_contract_404(client, fake_claude, db_session):
    # A clause owned by a different user must not be completable.
    other = User(email="other@e.com", auth_provider="guest")
    db_session.add(other)
    db_session.flush()
    c = Contract(user_id=other.id, title="X", file_url="local://x")
    db_session.add(c)
    db_session.flush()
    cl = Clause(contract_id=c.id, order=1,
                original_text="Some clause body text that is long enough.")
    db_session.add(cl)
    db_session.commit()

    resp = client.post(f"/contracts/{c.id}/clauses/{cl.id}/complete")
    assert resp.status_code == 404
