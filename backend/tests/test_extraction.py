import io
from docx import Document
from pypdf import PdfWriter
from app.extraction import extract_text, UnsupportedFileError
import pytest


def _make_docx_bytes(text: str) -> bytes:
    doc = Document()
    doc.add_paragraph(text)
    buf = io.BytesIO()
    doc.save(buf)
    return buf.getvalue()


def test_extract_docx():
    data = _make_docx_bytes("Hello clause one. Clause two follows.")
    text = extract_text(data, "contract.docx")
    assert "Hello clause one." in text


def test_extract_unknown_extension_raises():
    with pytest.raises(UnsupportedFileError):
        extract_text(b"x", "contract.txt")


def test_extract_pdf_empty_pages_ok():
    writer = PdfWriter()
    writer.add_blank_page(width=200, height=200)
    buf = io.BytesIO()
    writer.write(buf)
    text = extract_text(buf.getvalue(), "contract.pdf")
    assert isinstance(text, str)
