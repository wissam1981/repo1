"""Official Iraqi licensing-round glossary: loading, matching, prompt notes."""
from app.glossary import load_glossary, match_terms, official_renderings_note


def test_glossary_loads_with_official_terms():
    g = load_glossary()
    assert len(g) >= 80
    by_en = {e["en"]: e for e in g}
    # The official rendering of Abandonment is الهجر (not التخلي).
    assert "Abandonment" in by_en
    assert any("الهجر" == v["ar"] for v in by_en["Abandonment"]["ar"])


def test_match_terms_finds_terms_in_text():
    text = "The Contractor shall submit an Abandonment plan for the Field."
    matched = {e["en"] for e in match_terms(text)}
    assert "Abandonment" in matched


def test_renderings_note_built_and_empty_cases():
    note = official_renderings_note("Abandonment of the Field")
    assert "الهجر" in note
    assert "MUST use" in note
    assert official_renderings_note("zzz qqq") == ""
