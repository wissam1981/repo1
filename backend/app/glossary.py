"""Official EN→AR terminology from Iraqi licensing-round contract translations.

Built from 14 official Arabic translations (Halfaya, Majnoon, Badra, West
Qurna-2, Gharraf, Qayyarah, Najmah, Rumaila, Huwaiza, Naft Khana, Khashim
al-Ahmar, Khidr al-Mai, Integrated Gas + Rumaila English original) stored in
reference_corpus/. These renderings are authoritative for the app: when a
term has an official rendering, AI translations must use it.
"""
import json
import re
from functools import lru_cache
from pathlib import Path

_GLOSSARY_PATH = Path(__file__).parent / "data" / "official_glossary.json"


@lru_cache(maxsize=1)
def load_glossary() -> list[dict]:
    if not _GLOSSARY_PATH.exists():
        return []
    return json.loads(_GLOSSARY_PATH.read_text(encoding="utf-8"))


@lru_cache(maxsize=1)
def _compiled() -> list[tuple[re.Pattern, dict]]:
    return [
        (re.compile(r"\b" + re.escape(e["en"]) + r"\b", re.IGNORECASE), e)
        for e in load_glossary()
    ]


def match_terms(text: str) -> list[dict]:
    """Glossary entries whose English term appears in [text]."""
    return [e for pattern, e in _compiled() if pattern.search(text or "")]


def official_renderings_note(text: str, limit: int = 25) -> str:
    """Prompt block listing official Arabic renderings for terms in [text].

    Empty string when nothing matches, so callers can append unconditionally.
    """
    matches = match_terms(text)[:limit]
    if not matches:
        return ""
    lines = []
    for e in matches:
        variants = " / ".join(v["ar"] for v in e["ar"])
        lines.append(f"- {e['en']} = {variants}")
    return (
        "\n\nOFFICIAL ARABIC RENDERINGS (from official Iraqi licensing-round "
        "contract translations — when translating these terms to Arabic you "
        "MUST use these renderings, not your own):\n" + "\n".join(lines)
    )
