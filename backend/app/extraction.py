import io

from docx import Document
from pypdf import PdfReader


class UnsupportedFileError(ValueError):
    pass


def extract_text(data: bytes, filename: str) -> str:
    name = filename.lower()
    if name.endswith(".pdf"):
        return _extract_pdf(data)
    if name.endswith(".docx"):
        return _extract_docx(data)
    if name.endswith((".txt", ".md")):
        # Pre-converted contracts (e.g. OCR output) — tiny and exact.
        return data.decode("utf-8", errors="replace").strip()
    raise UnsupportedFileError(f"Unsupported file type: {filename}")


def _extract_pdf(data: bytes) -> str:
    """Extract text from a PDF.

    Prefers PyMuPDF (fitz), which generally reproduces font/character encoding
    more faithfully than pypdf (fewer 'i'->'t' style corruptions on PDFs with
    imperfect ToUnicode maps). Falls back to pypdf if PyMuPDF is unavailable or
    returns nothing.
    """
    text = _extract_pdf_pymupdf(data)
    if text.strip():
        return text.strip()
    return _extract_pdf_pypdf(data)


def _extract_pdf_pymupdf(data: bytes) -> str:
    try:
        import fitz  # PyMuPDF
    except ImportError:
        return ""
    try:
        parts = []
        with fitz.open(stream=data, filetype="pdf") as doc:
            for page in doc:
                parts.append(page.get_text("text") or "")
        return "\n".join(parts)
    except Exception:
        return ""


def _extract_pdf_pypdf(data: bytes) -> str:
    reader = PdfReader(io.BytesIO(data))
    parts = [(page.extract_text() or "") for page in reader.pages]
    return "\n".join(parts).strip()


def _extract_docx(data: bytes) -> str:
    doc = Document(io.BytesIO(data))
    return "\n".join(p.text for p in doc.paragraphs).strip()
