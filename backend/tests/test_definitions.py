"""Tests for definition detection, ordering, and clause cross-linking."""
from app.models import Contract, User
from app.services.contracts import (
    extract_defined_term,
    link_definitions,
    split_and_explain,
)
from tests.conftest import FakeClaude

DEF_ABANDON = '1.1 "Abandonment" means placing a Well permanently out of service.'
DEF_AFFILIATE = "1.4 'Affiliate' in relation to any entity, means a company which controls it."
OPERATIVE_USES_TERM = (
    "7.2 The Contractor shall submit an Abandonment plan for approval before "
    "any Well is placed out of service permanently."
)
OPERATIVE_PLAIN = (
    "9.1 Payment shall be made monthly within thirty (30) days of invoice."
)


def test_extract_defined_term():
    assert extract_defined_term(DEF_ABANDON) == "Abandonment"
    assert extract_defined_term(DEF_AFFILIATE) == "Affiliate"
    assert extract_defined_term(OPERATIVE_PLAIN) is None


def test_link_definitions_finds_usages():
    infos = link_definitions(
        [OPERATIVE_USES_TERM, DEF_ABANDON, OPERATIVE_PLAIN])
    by_term = {i["term"]: i for i in infos if i["is_definition"]}
    assert by_term["Abandonment"]["related"] == [0]  # index of the usage


def test_split_and_explain_puts_definitions_first_with_links(db_session):
    user = User(email="d@e.com", auth_provider="guest")
    db_session.add(user)
    db_session.flush()
    contract = Contract(user_id=user.id, title="T", file_url="local://x")
    db_session.add(contract)
    db_session.commit()

    # Split returns operative clause FIRST, definition second — the service
    # must reorder so the definition leads the journey.
    claude = FakeClaude(responses=[
        {"clauses": [OPERATIVE_USES_TERM, DEF_ABANDON]},
        {"simple_en": "def explained", "arabic": "شرح", "key_terms": []},
        {"simple_en": "op explained", "arabic": "شرح", "key_terms": []},
    ])
    split_and_explain(db_session, claude, contract, "full text")
    db_session.refresh(contract)

    clauses = sorted(contract.clauses, key=lambda c: c.order)
    assert clauses[0].is_definition is True
    assert clauses[0].original_text == DEF_ABANDON
    # The definition links to the operative clause's (1-based) order.
    assert clauses[0].related_orders == [2]
    assert clauses[1].is_definition is False
