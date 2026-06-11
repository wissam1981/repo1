import re

from sqlalchemy.orm import Session

from app.claude_client import ClaudeClient
from app.models import Clause, Contract

SPLIT_SYSTEM = (
    "You split legal contracts into individual clauses for an English learner. "
    "Return JSON: {\"clauses\": [\"clause text\", ...]} preserving original wording "
    "and order. Do not summarize. "
    "IGNORE the table of contents, page numbers, headers/footers, and any line "
    "that is only a heading followed by a page number — include only substantive "
    "clause body text."
)

# Safety caps to prevent runaway cost. 160 covers full Iraqi TSC contracts
# (~140 numbered sub-clauses) so the tutor sees the WHOLE contract; trivial
# fragments are dropped before they ever reach the AI.
MAX_CLAUSES = 160
MIN_CLAUSE_LEN = 25

# Dotted table-of-contents leader ending in a page number, e.g.
# "ARTICLE 34 - HEADINGS .......... 56"
_TOC_DOTTED = re.compile(r"\.{4,}\s*[,.]*\s*\d{1,4}\s*$")
# A short heading that ends in a bare page number (no sentence body), e.g.
# "ARTICLE 13 - JOINT MANAGEMENT OF PETROLEUM OPERATIONS 32"
_TOC_HEADING = re.compile(r"\s\d{1,4}\s*$")
# A line that is only digits / punctuation / dots / pipes.
_ONLY_NOISE = re.compile(r"^[\d\s.,;:|_/\\\-–—]+$")


def _is_noise_clause(text: str) -> bool:
    """True if a candidate clause is table-of-contents / page-number noise."""
    raw = (text or "").strip()
    # Collapse internal whitespace/newlines so multi-line fragments like
    # "55\nt\n-" are evaluated as the single noise token "55 t -".
    t = re.sub(r"\s+", " ", raw).strip()
    if len(t) < MIN_CLAUSE_LEN:
        return True
    if _ONLY_NOISE.match(t):
        return True
    if _TOC_DOTTED.search(t):
        return True
    # A run of 5+ dots is a table-of-contents dotted leader; real prose uses at
    # most an ellipsis (3 dots). Catches multi-line TOC clumps too.
    if re.search(r"\.{5,}", t):
        return True
    # Short heading-only line ending in a page number, with no sentence body.
    if len(t) < 120 and _TOC_HEADING.search(t) and t.count(".") < 2:
        return True
    # Mostly-uppercase short text is a heading / table-of-contents entry, not a
    # real clause. Real clause bodies have lowercase sentence text. This catches
    # "ARTICLE 13 - JOINT MANAGEMENT OF PETROLEUM OPERATIONS" and the garbled
    # "32 ARTICLE ARTICLE ARTICLE ..." fragments that have no page number.
    letters = [ch for ch in t if ch.isalpha()]
    if letters and len(t) < 160:
        lower_ratio = sum(ch.islower() for ch in letters) / len(letters)
        if lower_ratio < 0.25:
            return True
    return False


def _clean_clauses(texts: list[str]) -> list[str]:
    """Drop noise clauses and cap the total to MAX_CLAUSES."""
    cleaned = [t.strip() for t in texts if not _is_noise_clause(t)]
    return cleaned[:MAX_CLAUSES]

EXPLAIN_SYSTEM = (
    "You explain one contract clause to an Arabic-speaking English learner. "
    "Return JSON with keys: simple_en (plain-English explanation), "
    "arabic (Arabic translation of the explanation), "
    "key_terms (array of {term, meaning} for important legal words)."
)

# Definitions get an exhaustive treatment: they are the foundation the learner
# needs before reading the operative clauses.
EXPLAIN_DEFINITION_SYSTEM = (
    "You teach one DEFINITION clause from a legal contract to an Arabic-"
    "speaking English learner, in exhaustive detail. Return JSON with keys: "
    "simple_en (a thorough plain-English explanation: what the term means, "
    "why contracts define it, and one concrete example of how it is used), "
    "arabic (a detailed Arabic explanation covering the same points), "
    "key_terms (array of {term, meaning} for every legal word in the clause)."
)

# "1.1 \"Abandonment\" means ..." / "1.2 'Affiliate' in relation to ..."
_DEFINITION_RE = re.compile(
    r"""^\s*\d+\.\d+\s*["'‘’“”]\s*([A-Z][A-Za-z0-9 \-/&()]{1,60}?)\s*["'‘’“”]""",
)


def extract_defined_term(text: str) -> str | None:
    """Return the defined term if this clause is a definition, else None."""
    m = _DEFINITION_RE.match((text or "").strip())
    return m.group(1).strip() if m else None


def link_definitions(texts: list[str]) -> list[dict]:
    """Annotate each clause text with definition info and cross-references.

    Returns one dict per clause: {text, is_definition, term, related: [idx...]}
    where `related` holds, for a definition, the indices of NON-definition
    clauses that use the defined term (case-insensitive whole-word match).
    """
    infos = []
    for text in texts:
        term = extract_defined_term(text)
        infos.append({
            "text": text,
            "is_definition": term is not None,
            "term": term,
            "related": [],
        })

    for info in infos:
        if not info["is_definition"]:
            continue
        pattern = re.compile(
            r"\b" + re.escape(info["term"]) + r"\b", re.IGNORECASE)
        info["related"] = [
            i for i, other in enumerate(infos)
            if not other["is_definition"] and pattern.search(other["text"])
        ]
    return infos


def _strip_page_noise(full_text: str) -> str:
    """Remove repeated page headers/footers and bare page-number lines.

    PDF extraction repeats the running header on every page (e.g. the
    contract title block) and leaves standalone page numbers; both pollute
    clause text and break article-number detection.
    """
    from collections import Counter

    lines = full_text.splitlines()
    counts = Counter(line.strip() for line in lines if line.strip())
    cleaned = []
    for line in lines:
        s = line.strip()
        if s and len(s) > 8 and counts[s] >= 4:
            continue  # running header/footer
        if re.fullmatch(r"\d{1,3}", s):
            continue  # bare page number
        cleaned.append(line)
    return "\n".join(cleaned)


def _local_split(full_text: str) -> list[str]:
    """Split contract text into clauses without using AI.

    Used as a fallback when the Claude API is unavailable (e.g. no/invalid API
    key). Heuristics, in order of preference:
      1. Numbered/section headers (e.g. "1.", "1.2", "Section 3", "Article 4").
      2. Blank-line separated paragraphs.
      3. The whole text as a single clause.
    """
    text = full_text.strip()
    if not text:
        return []

    # 1. Try splitting on numbered/section markers at the start of a line.
    pattern = re.compile(
        r"(?im)^\s*(?:(?:section|article|clause)\s+)?\d+(?:\.\d+)*[\.\)]?\s+"
    )
    matches = list(pattern.finditer(text))
    if len(matches) >= 2:
        clauses: list[str] = []
        for i, m in enumerate(matches):
            start = m.start()
            end = matches[i + 1].start() if i + 1 < len(matches) else len(text)
            chunk = text[start:end].strip()
            if chunk:
                clauses.append(chunk)
        if clauses:
            return clauses

    # 2. Fall back to blank-line separated paragraphs.
    paragraphs = [p.strip() for p in re.split(r"\n\s*\n", text) if p.strip()]
    if len(paragraphs) >= 2:
        return paragraphs

    # 3. Single clause.
    return [text]


def _safe_split(claude: ClaudeClient, full_text: str) -> list[str]:
    """Split via Claude, falling back to local heuristics on any failure.

    The result is always cleaned of table-of-contents / page-number noise and
    capped at MAX_CLAUSES, regardless of which path produced it.
    """
    texts: list[str] = []
    try:
        split = claude.complete_json(SPLIT_SYSTEM, full_text)
        texts = split.get("clauses", []) or []
    except Exception:
        texts = []
    if not texts:
        texts = _local_split(full_text)
    return _clean_clauses(texts)


def _safe_explain(claude: ClaudeClient, text: str,
                  is_definition: bool = False) -> dict:
    """Explain a clause via Claude, returning empty explanation on failure.

    Definition clauses get the exhaustive teaching prompt.
    """
    system = EXPLAIN_DEFINITION_SYSTEM if is_definition else EXPLAIN_SYSTEM
    from app.glossary import official_renderings_note
    prompt = text + official_renderings_note(text)
    try:
        explanation = claude.complete_json(system, prompt)
        return {
            "simple_en": explanation.get("simple_en"),
            "arabic": explanation.get("arabic"),
            "key_terms": explanation.get("key_terms", []),
        }
    except Exception:
        # No AI available — store the clause with no explanation yet.
        return {"simple_en": None, "arabic": None, "key_terms": []}


def split_and_explain(db: Session, claude: ClaudeClient,
                      contract: Contract, full_text: str,
                      on_progress=None) -> None:
    """Split, order definitions first, explain, cross-link, persist.

    All AI work happens BEFORE the database transaction. This keeps the DB
    write short (single commit) so SQLite never blocks other requests, and
    lets [on_progress] report `(stage, done, total)` to the upload UI.
    """
    def report(stage: str, done: int, total: int) -> None:
        if on_progress is not None:
            on_progress(stage, done, total)

    report("splitting", 0, 1)
    texts = _safe_split(claude, _strip_page_noise(full_text))

    # The learner journey starts with the definitions: they are the vocabulary
    # foundation for everything else. Definitions keep their original relative
    # order, followed by the operative clauses in theirs.
    infos = link_definitions(texts)
    infos.sort(key=lambda i: not i["is_definition"])

    # After reordering, recompute cross-references so `related` holds indices
    # into the REORDERED list (converted to 1-based clause orders below).
    original = link_definitions([i["text"] for i in infos])

    total = len(infos)
    rows: list[dict] = []
    explained_any = False
    for idx, info in enumerate(original):
        report("explaining", idx, total)
        explanation = _safe_explain(
            claude, info["text"], is_definition=info["is_definition"])
        if explanation["simple_en"] is not None:
            explained_any = True
        rows.append({
            "order": idx + 1,
            "text": info["text"],
            "is_definition": info["is_definition"],
            "related_orders": [r + 1 for r in info["related"]],
            **explanation,
        })
    report("saving", total, total)

    # Single short write transaction.
    for row in rows:
        db.add(Clause(
            contract_id=contract.id,
            order=row["order"],
            original_text=row["text"],
            simple_en=row["simple_en"],
            arabic=row["arabic"],
            key_terms=row["key_terms"],
            is_definition=row["is_definition"],
            related_orders=row["related_orders"],
        ))

    contract.status = "explained" if explained_any else "parsed"
    db.commit()
