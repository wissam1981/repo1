"""Tests for the AI-free fallback path in contract processing.

These verify that uploads still produce clauses when the Claude API is
unavailable (e.g. invalid API key), so the app works end-to-end offline.
"""
from app.models import Contract, User
from app.services.contracts import (
    MAX_CLAUSES,
    _clean_clauses,
    _is_noise_clause,
    _local_split,
    _safe_split,
    split_and_explain,
)


class StaticClaude:
    """Returns a fixed split response, then empty explanations."""

    def __init__(self, clauses):
        self._clauses = clauses

    def complete_json(self, system, user, *, fast=False):
        if "split" in system.lower() or "clause" in system.lower():
            return {"clauses": self._clauses}
        return {"simple_en": "x", "arabic": "س", "key_terms": []}


class FailingClaude:
    """A Claude client that always raises, simulating an invalid API key."""

    def complete_json(self, system, user, *, fast=False):
        raise RuntimeError("invalid x-api-key")


def test_local_split_on_numbered_sections():
    text = "1. The term is 12 months.\n2. Payment is due monthly.\n3. Either party may terminate."
    clauses = _local_split(text)
    assert len(clauses) == 3
    assert clauses[0].startswith("1.")
    assert "Payment" in clauses[1]


def test_local_split_on_paragraphs():
    text = "First paragraph of the agreement.\n\nSecond paragraph here.\n\nThird one."
    clauses = _local_split(text)
    assert len(clauses) == 3


def test_local_split_single_block():
    text = "A short one-line contract with no structure."
    clauses = _local_split(text)
    assert clauses == [text]


def test_local_split_empty():
    assert _local_split("   ") == []


def test_is_noise_clause_filters_toc_and_page_numbers():
    # Page numbers / punctuation-only
    assert _is_noise_clause("23")
    assert _is_noise_clause("  55 ")
    assert _is_noise_clause("t")
    assert _is_noise_clause("-")
    # Dotted table-of-contents leaders ending in a page number
    assert _is_noise_clause("ARTICLE 34 - HEADINGS OF ARTICLES ............ 56")
    # Short heading-only line ending in a page number
    assert _is_noise_clause("ARTICLE 13 - JOINT MANAGEMENT OF PETROLEUM 32")
    # Real clauses are kept
    assert not _is_noise_clause("The term of this Agreement is twelve (12) months.")
    assert not _is_noise_clause(
        "Either party may terminate this Agreement by giving sixty days notice."
    )


def test_clean_clauses_drops_noise_and_caps():
    raw = ["23", "27", "ARTICLE 13 - JOINT MANAGEMENT 32",
           "The term of this Agreement is twelve (12) months.",
           "Payment shall be made monthly within thirty (30) days."]
    cleaned = _clean_clauses(raw)
    assert cleaned == [
        "The term of this Agreement is twelve (12) months.",
        "Payment shall be made monthly within thirty (30) days.",
    ]


def test_clean_clauses_enforces_max_cap():
    # 200 valid clauses should be capped to MAX_CLAUSES.
    raw = [f"Clause number {i} states an obligation of the parties herein."
           for i in range(200)]
    cleaned = _clean_clauses(raw)
    assert len(cleaned) == MAX_CLAUSES


def test_safe_split_caps_runaway_local_split():
    # A table-of-contents-like blob that naive splitting would explode into
    # hundreds of junk clauses is cleaned + capped.
    toc = "\n".join(f"ARTICLE {i} - SOME HEADING {i + 20}" for i in range(300))
    claude = StaticClaude(clauses=[])  # forces local fallback
    result = _safe_split(claude, toc)
    assert len(result) <= MAX_CLAUSES


def test_split_and_explain_falls_back_when_claude_fails(db_session):
    user = User(email="u@e.com", auth_provider="guest")
    db_session.add(user)
    db_session.flush()
    contract = Contract(user_id=user.id, title="T", file_url="local://x.pdf")
    db_session.add(contract)
    db_session.commit()

    full_text = (
        "1. The term of this Agreement is twelve (12) months.\n"
        "2. Payment shall be made monthly within thirty (30) days."
    )
    split_and_explain(db_session, FailingClaude(), contract, full_text)
    db_session.refresh(contract)

    # Contract still gets clauses, even though Claude was unavailable.
    assert len(contract.clauses) == 2
    assert contract.clauses[0].original_text.startswith("1.")
    # No AI explanation available, so status stays "parsed".
    assert contract.status == "parsed"
    assert contract.clauses[0].simple_en is None
