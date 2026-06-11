from app.cefr import estimate_cefr_level, CEFRLevel


def test_cefr_from_scores():
    assert estimate_cefr_level([0.2, 0.25]) == CEFRLevel.A1
    assert estimate_cefr_level([0.35, 0.4]) == CEFRLevel.A2
    assert estimate_cefr_level([0.45, 0.5]) == CEFRLevel.B1
    assert estimate_cefr_level([0.6, 0.65]) == CEFRLevel.B2
    assert estimate_cefr_level([0.75, 0.8]) == CEFRLevel.C1
    assert estimate_cefr_level([0.88, 0.9]) == CEFRLevel.C2


def test_empty_scores_defaults_to_a1():
    assert estimate_cefr_level([]) == CEFRLevel.A1


def test_mixed_scores_averages():
    scores = [0.2, 0.8]  # avg 0.5 → B1
    assert estimate_cefr_level(scores) == CEFRLevel.B1
