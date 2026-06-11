"""Tutor session orchestration: create sessions, append messages, run turns."""
from sqlalchemy.orm import Session

from app.claude_client import ClaudeClient
from app.models import Contract, TutorSession, User

TUTOR_SYSTEM = (
    "You are an expert bilingual (English/Arabic) tutor for legal contracts. The user is learning English and reading contracts. "
    "You ask questions about the contract, correct mistakes, explain vocabulary, and adapt difficulty. "
    "IMPORTANT: You must provide highly comprehensive and detailed answers covering the entire contract and its vocabulary. "
    "CITATION RULES (strict): the contract text below labels each clause with "
    "its real number from the contract, e.g. [Article 19.5]. When referring "
    "to a location, cite EXACTLY those Article numbers — 'Article 19.5' in "
    "English or 'المادة 19.5' in Arabic. NEVER use the word Clause and NEVER "
    "invent or guess a number: only cite an Article number if the relevant "
    "text actually appears under that label below, and when you cite one "
    "you MUST include a short verbatim quote (\"...\") from that Article as "
    "proof. If the quoted text has no visible article number of its own "
    "(e.g. scanned definitions whose numbering was lost), do NOT supply one "
    "— describe the location instead ('within the definitions article'). "
    "If a term is used but never defined, say exactly that and "
    "quote where it is used. If something is not in the contract text "
    "provided, say clearly that it is not mentioned in the contract — do "
    "not answer from general knowledge as if it were. "
    "If the user asks a question in Arabic, you MUST reply in Arabic. If they ask in English, reply in English. "
    "On incorrect answers, explain thoroughly and move to easier questions. On correct answers, increase difficulty slightly. "
    "Return JSON: {\"message\": \"...\", \"new_difficulty\": 1-5}"
)

# Hard cap on contract text included per turn (~15K tokens) so very large
# contracts cannot blow the model's context window or the bill.
MAX_CONTEXT_CHARS = 60_000


def create_session(db: Session, user: User, contract: Contract) -> TutorSession:
    session = TutorSession(user_id=user.id, contract_id=contract.id, messages=[])
    db.add(session)
    db.commit()
    db.refresh(session)
    return session


def add_message(db: Session, session: TutorSession, role: str, content: str) -> None:
    # Reassign the list so SQLAlchemy detects the mutation on the JSON column.
    session.messages = [*session.messages, {"role": role, "content": content}]
    db.commit()


def get_session_context(session: TutorSession) -> str:
    """Build context string from the FULL contract + recent messages.

    Clauses are numbered by their stored `order` (the numbers the student
    sees in the app), definitions are flagged so the tutor can teach
    vocabulary precisely, and the total contract text is capped.
    """
    contract = session.contract
    context = f"Contract: {contract.title}\n"
    context += "Contract Full Text:\n"
    used = 0
    import re as _re
    for c in sorted(contract.clauses, key=lambda x: x.order):
        # Label with the REAL article number from the contract text (e.g.
        # "19.5 Contractor shall..." → [Article 19.5]) so citations match
        # the printed contract, not the app's internal ordering.
        head = (c.original_text or "")[:300]
        m = _re.search(r"\b(\d{1,2}\.\d{1,3})\b", head) or \
            _re.match(r"\s*(\d{1,2})\b", head)
        label = f"Article {m.group(1)}" if m else f"Part {c.order}"
        tag = " (DEFINITION)" if getattr(c, "is_definition", False) else ""
        entry = f"[{label}]{tag} {c.original_text}\n"
        if used + len(entry) > MAX_CONTEXT_CHARS:
            context += "... (remaining clauses omitted for length)\n"
            break
        context += entry
        used += len(entry)
    # Official terminology reference: the tutor must use these renderings
    # when explaining terms in Arabic.
    from app.glossary import load_glossary
    glossary = load_glossary()
    if glossary:
        context += "\nOFFICIAL ARABIC RENDERINGS (Iraqi licensing-round "
        context += "translations — always use these when translating these "
        context += "terms):\n"
        for e in glossary:
            variants = " / ".join(v["ar"] for v in e["ar"])
            context += f"- {e['en']} = {variants}\n"
    context += "\nRecent conversation:\n"
    for msg in session.messages[-10:]:  # last 10 messages
        context += f"{msg['role'].upper()}: {msg['content']}\n"
    return context


def get_tutor_response(db: Session, claude: ClaudeClient, session: TutorSession) -> dict:
    """Get the next tutor message and persist it."""
    context = get_session_context(session)
    difficulty_hint = f"Current difficulty level: {session.difficulty}/5"
    prompt = f"{context}\n{difficulty_hint}\nContinue the conversation. Respond in JSON format."

    response = claude.complete_json(TUTOR_SYSTEM, prompt)
    message = response.get("message", "")
    new_difficulty = response.get("new_difficulty", session.difficulty)

    add_message(db, session, "assistant", message)
    session.difficulty = new_difficulty
    db.commit()

    return {"message": message, "new_difficulty": new_difficulty}
