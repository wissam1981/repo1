"""Vocabulary endpoints: save words, list due reviews, record review outcomes."""
from collections import OrderedDict

from fastapi import APIRouter, Depends, HTTPException, Response, status
from sqlalchemy.orm import Session

from app.auth import JwtError, decode_jwt
from app.config import get_settings
from app.db import get_db
from app.deps import get_claude, get_current_user
from app.models import Clause, Review, User
from app.schemas import ReviewOutcome, TapIn, TapOut, WordIn, WordOut
from app.services.vocabulary import apply_review_outcome, list_due_words, save_word

router = APIRouter(prefix="/vocabulary", tags=["vocabulary"])

# Synthesized audio cache: the same words/clauses are replayed often and each
# synthesis costs money. Capped LRU keyed by lowercased text.
_AUDIO_CACHE: OrderedDict[str, bytes] = OrderedDict()
_AUDIO_CACHE_MAX = 500


def get_speech():
    """Dependency returning the speech synthesizer (overridable in tests)."""
    from app.openai_client import synthesize_speech
    return synthesize_speech


@router.get("/pronounce")
def pronounce(
    text: str,
    token: str,
    db: Session = Depends(get_db),
    synthesize=Depends(get_speech),
) -> Response:
    """Natural AI pronunciation of [text] as MP3.

    Auth comes via the `token` query parameter (not the Authorization header)
    because browser/AVPlayer audio elements cannot attach custom headers.
    """
    settings = get_settings()
    try:
        payload = decode_jwt(token, secret=settings.jwt_secret,
                             algorithm=settings.jwt_algorithm)
    except JwtError:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Invalid token")
    if db.get(User, int(payload["sub"])) is None:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Unknown user")

    clean = text.strip()[:800]
    if not clean:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, "Empty text")

    key = clean.lower()
    audio = _AUDIO_CACHE.get(key)
    if audio is None:
        try:
            audio = synthesize(clean)
        except Exception:
            raise HTTPException(
                status.HTTP_503_SERVICE_UNAVAILABLE,
                "Speech synthesis unavailable",
            )
        _AUDIO_CACHE[key] = audio
        if len(_AUDIO_CACHE) > _AUDIO_CACHE_MAX:
            _AUDIO_CACHE.popitem(last=False)
    else:
        _AUDIO_CACHE.move_to_end(key)

    return Response(content=audio, media_type="audio/mpeg",
                    headers={"Cache-Control": "private, max-age=86400"})

TAP_SYSTEM = (
    "You define one English word/phrase from a legal contract for an Arabic-"
    "speaking English learner. "
    "CRITICAL: if the prompt includes the contract's own definition of the "
    "term, your meaning MUST follow that contract definition — NOT the "
    "general/common meaning (e.g. if the contract defines 'NOC' as North Oil "
    "Company, never say No Objection Certificate). Otherwise use the meaning "
    "the term has in the provided clause context. "
    "NEVER give vague answers like 'refers to an entity mentioned in the "
    "contract' — always state concretely what the term means here; if it is "
    "an abbreviation, expand it. "
    'Return JSON: {"meaning_en": "clear concise English meaning", '
    '"meaning_ar": "شرح واضح بالعربية", '
    '"example": "one short English example sentence using the term"}.'
)


def _contract_definition_clause(contract, term: str):
    """The contract's definition clause for [term], if the contract defines it."""
    from app.services.contracts import extract_defined_term

    wanted = term.strip().lower()
    for c in contract.clauses:
        if not getattr(c, "is_definition", False):
            continue
        defined = extract_defined_term(c.original_text)
        if defined and defined.lower() == wanted:
            return c
    return None


@router.post("/tap", response_model=TapOut, status_code=status.HTTP_201_CREATED)
def tap_word(
    body: TapIn,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
    claude=Depends(get_claude),
) -> TapOut:
    """Look up a tapped word with AI and save it to the user's vocabulary."""
    clause = None
    if body.clause_id is not None:
        clause = db.get(Clause, body.clause_id)
        if clause is None or clause.contract.user_id != user.id:
            raise HTTPException(status.HTTP_404_NOT_FOUND, "Clause not found")

    # Ground the lookup in THIS contract: its own definition of the term (if
    # any) takes priority over the general meaning, and the tapped clause
    # provides disambiguating context.
    prompt = f"Term: {body.term}"
    if clause is not None:
        defn = _contract_definition_clause(clause.contract, body.term)
        if defn is not None:
            prompt += (
                "\n\nThe contract DEFINES this term as follows — the meaning "
                f"MUST follow this definition:\n{defn.original_text[:1200]}"
            )
        prompt += (
            "\n\nClause where the user tapped the term:\n"
            f"{clause.original_text[:1500]}"
        )

    # Official Iraqi licensing-round renderings are authoritative for Arabic.
    from app.glossary import official_renderings_note
    prompt += official_renderings_note(body.term)

    try:
        result = claude.complete_json(TAP_SYSTEM, prompt, fast=True)
        meaning_en = result.get("meaning_en") or result.get("meaning", "")
        meaning_ar = result.get("meaning_ar", "")
        example = result.get("example", "")
    except Exception:
        raise HTTPException(
            status.HTTP_503_SERVICE_UNAVAILABLE, "Word lookup unavailable"
        )

    # The stored Word keeps a single combined meaning (review screens show
    # one line); the tap response carries both languages separately so the
    # word card can lay them out properly.
    combined = meaning_en + (f" — {meaning_ar}" if meaning_ar else "")
    word = save_word(db, user, body.term, combined, example, clause)
    return TapOut(word_id=word.id, term=word.term,
                  meaning=word.meaning, example=word.example,
                  meaning_en=meaning_en, meaning_ar=meaning_ar)


@router.post("/words", response_model=WordOut, status_code=status.HTTP_201_CREATED)
def create_word(
    body: WordIn,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> WordOut:
    """Save a new vocabulary word and create its initial review record."""
    clause = None
    if body.clause_id is not None:
        clause = db.get(Clause, body.clause_id)
        if clause is None or clause.contract.user_id != user.id:
            raise HTTPException(status.HTTP_404_NOT_FOUND, "Clause not found")
    word = save_word(db, user, body.term, body.meaning, body.example, clause)
    return word


@router.get("/due", response_model=list[WordOut])
def get_due_words(
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> list:
    """Return all words whose next review is due now or in the past."""
    return list_due_words(db, user)


@router.put("/reviews/{review_id}", status_code=status.HTTP_200_OK)
def record_review(
    review_id: int,
    body: ReviewOutcome,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
) -> dict:
    """Record the outcome of a vocabulary review and update the SM-2 schedule."""
    review = db.get(Review, review_id)
    if review is None or review.word.user_id != user.id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Review not found")
    apply_review_outcome(db, review, body.quality)
    return {"status": "ok"}
