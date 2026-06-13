# Contract Journey Redesign — Implementation Plan

> **For agentic workers:** Executed inline in-session (executing-plans). Spec: `docs/superpowers/specs/2026-06-10-contract-journey-redesign-design.md`

**Goal:** Rebuild the app as one guided journey (clause = learning unit) with navy/gold identity and ar/en bilingual UI.

**Architecture:** Backend gains clause completion + tap-a-word lookup; Flutter frontend gets a new theme, locale system, Journey + Clause Study screens, and auto-session tutor. Existing services (SM-2, quizzes, tutor, CEFR) are reused, not rewritten.

**Tech stack:** FastAPI + SQLAlchemy + GPT (existing), Flutter web (existing providers pattern).

---

## Task 1: Backend — clause completion (TDD)
- Modify `backend/app/models.py`: `Clause.completed_at: Mapped[datetime | None]`.
- Modify `backend/app/schemas.py`: `ClauseOut.completed: bool` (computed from completed_at via validator) — keep `from_attributes`.
- Create `POST /contracts/{contract_id}/clauses/{clause_id}/complete` in contracts_router (ownership check; sets completed_at; returns ClauseOut).
- Tests: complete marks clause; foreign clause 403/404; ClauseOut.completed serialized.
- Note: SQLite table exists → `Base.metadata.create_all` won't add the column; add tiny startup migration (ALTER TABLE if column missing) in main.py.

## Task 2: Backend — tap-a-word (TDD)
- `POST /vocabulary/tap` body `{term: str, clause_id: int | None}` → claude.complete_json (fast=True) system: return JSON {meaning, example} for a legal-English term, meaning concise EN + AR gloss → save via existing vocabulary service (save_word creates Word + initial Review) → return `{word_id, term, meaning, example}`.
- On AI failure → 503 `{detail: "lookup unavailable"}` (do not save).
- Tests with FakeClaude: saves word + review; failure path 503.

## Task 3: Frontend — theme + locale
- Create `lib/theme.dart`: navy/gold ThemeData (colors per spec).
- Create `lib/l10n/strings.dart`: `AppStrings.of(locale)` ar/en maps for all UI strings.
- Create `lib/providers/locale_provider.dart`: ChangeNotifier, `locale` ('ar'|'en'), toggle();
- main.dart: MultiProvider + Directionality driven by locale; theme applied.

## Task 4: Frontend — JourneyScreen (new home)
- Create `lib/screens/journey.dart`: loads contracts; if none → upload CTA (reuse upload flow from old home); else: header (title, streak placeholder from quiz history, CEFR from /auth? — use dashboard data already available via providers), progress bar (completed/total from clauses), gold Today card (first incomplete clause) → ClauseStudyScreen, clause path list (done/current/locked).
- Route '/home' → JourneyScreen (login + splash unchanged).

## Task 5: Frontend — ClauseStudyScreen (core)
- Create `lib/screens/clause_study.dart` taking contract + clause.
- Stage chips (Read → Understand → Quiz). Read: clause.originalText words wrapped in InkWell → calls VocabularyProvider.tapWord(term, clauseId) → bottom sheet with meaning/example + "saved" notice. Understand: simple_en, arabic, key-term chips. Quiz: generate (clause_id, mcq, 3) via QuizzesProvider, answer inline, submit → score ≥ 2/3 → ContractsProvider.completeClause → celebration dialog → pop to Journey (refreshed).
- Tutor FAB → TutorScreen with contractId.

## Task 6: Frontend — providers wiring
- ContractsProvider: `completeClause(contractId, clauseId)`; clause model gains `completed`.
- VocabularyProvider: `tapWord(term, clauseId)` → POST /vocabulary/tap.
- TutorProvider: `ensureSession(contractId)` auto-create on screen open.

## Task 7: Frontend — restyle Vocabulary, Tutor, Progress
- Vocabulary: due cards restyled navy/gold; keep review grading buttons (SM-2 quality).
- Tutor: auto-session on init (needs contractId param or first contract); chat bubbles navy/gold.
- Progress (ex-dashboard): real stats; plan items navigate (journey / vocabulary / tutor).

## Task 8: Tests + build + deploy + verify
- Update frontend widget tests for new screens/strings; `flutter analyze` clean enough; `flutter test` green; `flutter build web --release`; restart :9000 server; backend pytest green; live E2E: complete-clause + tap-word via curl; screenshot via preview.

## Self-review notes
- Type consistency: Clause model field `completed` mirrors backend bool; tap endpoint returns word_id used nowhere yet (fine).
- Risk: existing SQLite needs ALTER for completed_at (handled in Task 1 note).
- YAGNI: no per-user progress table (contract is per-user already); no TTS.
