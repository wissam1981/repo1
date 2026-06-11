"""CEFR level estimation from quiz scores. Pure logic, no I/O."""
from enum import Enum
from statistics import mean


class CEFRLevel(str, Enum):
    A1 = "A1"
    A2 = "A2"
    B1 = "B1"
    B2 = "B2"
    C1 = "C1"
    C2 = "C2"


CEFR_THRESHOLDS = [
    (0.3, CEFRLevel.A1),
    (0.4, CEFRLevel.A2),
    (0.55, CEFRLevel.B1),
    (0.7, CEFRLevel.B2),
    (0.85, CEFRLevel.C1),
    (1.0, CEFRLevel.C2),  # >= 0.85 → C2
]


def estimate_cefr_level(scores: list[float]) -> CEFRLevel:
    """
    Estimate CEFR level from a list of quiz scores (0.0–1.0).
    If empty, default to A1. Otherwise, average and map to level.
    """
    if not scores:
        return CEFRLevel.A1
    avg_score = mean(scores)
    for threshold, level in CEFR_THRESHOLDS:
        if avg_score < threshold:
            return level
    return CEFRLevel.C2  # fallback
