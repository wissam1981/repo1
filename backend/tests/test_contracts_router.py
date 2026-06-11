import io
from docx import Document


def _docx_bytes(text: str) -> bytes:
    doc = Document()
    doc.add_paragraph(text)
    buf = io.BytesIO()
    doc.save(buf)
    return buf.getvalue()


def test_upload_contract_returns_explained_clauses(client, fake_claude):
    fake_claude._responses = [
        {"clauses": ["The term of this Agreement is twelve (12) months.",
                     "Either party may terminate with sixty (60) days notice."]},
        {"simple_en": "S1", "arabic": "ع1", "key_terms": []},
        {"simple_en": "S2", "arabic": "ع2", "key_terms": []},
    ]
    files = {"file": ("c.docx", _docx_bytes("Whole contract."),
                      "application/vnd.openxmlformats-officedocument.wordprocessingml.document")}
    resp = client.post("/contracts", files=files, data={"title": "My Contract"})
    # Upload returns immediately; processing happens in the background.
    assert resp.status_code == 201
    assert resp.json()["status"] == "processing"
    cid = resp.json()["id"]

    # TestClient runs the background task before returning, so the processed
    # result is already visible.
    body = client.get(f"/contracts/{cid}").json()
    assert body["status"] == "explained"
    assert len(body["clauses"]) == 2
    assert body["clauses"][0]["simple_en"] == "S1"

    progress = client.get(f"/contracts/{cid}/progress").json()
    assert progress["percent"] == 100


def test_upload_unsupported_file_returns_400(client):
    files = {"file": ("c.txt", b"hi", "text/plain")}
    resp = client.post("/contracts", files=files, data={"title": "X"})
    assert resp.status_code == 400


def test_get_contract_returns_clauses(client, fake_claude):
    fake_claude._responses = [
        {"clauses": ["The parties agree to keep all information confidential."]},
        {"simple_en": "S", "arabic": "ع", "key_terms": []},
    ]
    up = client.post("/contracts",
                     files={"file": ("c.docx", _docx_bytes("x"),
                            "application/vnd.openxmlformats-officedocument.wordprocessingml.document")},
                     data={"title": "T"})
    cid = up.json()["id"]
    resp = client.get(f"/contracts/{cid}")
    assert resp.status_code == 200
    assert resp.json()["clauses"][0]["simple_en"] == "S"
