# Contract Journey — Full Redesign Spec

**Date:** 2026-06-10
**Approved by:** user (visual mockup approved)
**Goal:** Transform the app from 5 disconnected tool-screens into one guided learning journey, with a premium legal (navy + gold) gamified visual identity and a bilingual (Arabic/English) interface.

## Problem

The original idea — "learn English through YOUR contract" — is invisible in the current app:
- Home is a file list; Vocabulary/Quiz/Tutor screens are empty dead-ends with no connecting flow.
- Dashboard "Today's Plan" items are static text, not actions.
- Words never flow from reading (no tap-a-word); quizzes have no generate path in UI; tutor fails without a session and never tells the user why.

## Concept: The Journey

The **clause is the unit of learning**. The app opens directly into the journey:

1. **Journey screen (new Home):** contract title, progress bar (clauses completed / total), streak flame, CEFR badge, gold "Today's clause" card with a single CTA, and the clause path list (completed ✓ / current ▶ / locked 🔒). If no contract exists: upload CTA.
2. **Clause Study screen (new, core):** three stages —
   - **Read:** original English text, every word tappable → popup with meaning (GPT fast model) → word auto-saved to vocabulary (SM-2 review scheduled).
   - **Understand:** simple English + Arabic explanation + key-term chips (from existing clause data).
   - **Quiz:** 3 MCQ questions generated for THIS clause (existing /quizzes/generate with clause_id); submit → score; pass marks clause complete → small celebration → next clause unlocks.
   - Contextual tutor FAB: opens tutor with a session auto-created for this contract.
3. **Vocabulary screen:** review-due words (existing SM-2), shown as cards; words arrive automatically from reading taps. Restyled.
4. **Tutor screen:** session auto-created on open (current contract); no dead "No tutor session" state. Restyled.
5. **Progress screen (ex-Dashboard):** clauses completed, words saved, quiz accuracy, streak, CEFR level — all real numbers; plan items are tappable links into the journey. Restyled.

## Visual identity

- **Navy + gold (legal luxury):** navy `#042C53` surfaces, lighter navy `#0C447C` cards, gold `#EF9F27`/`#FAC775` accents and CTAs, light blue `#B5D4F4/#E6F1FB` text on navy. Reading surface: light (`#E6F1FB`) card with navy text for legibility.
- **Gamification:** streak flame, progress bar, clause-complete celebration (snackbar/dialog with gold check), locked/unlocked path.
- **Typography:** default Flutter fonts; weights 400/500; generous line-height for clause reading.

## Bilingual UI

- All UI strings via a lightweight `AppStrings` lookup (ar/en maps) + `LocaleProvider` (ChangeNotifier) with a toggle button (ع/EN) in the Journey app bar.
- Arabic = RTL via `Directionality`; English = LTR. Learning content (clause text) always LTR English.
- Default: Arabic.

## Backend additions (minimal)

1. `Clause.completed_at` (nullable DateTime) — completion tracking.
   - `POST /contracts/{contract_id}/clauses/{clause_id}/complete` → sets completed_at, returns clause. Ownership enforced.
   - `ClauseOut` gains `completed: bool`.
2. `POST /vocabulary/tap` `{term, clause_id?}` → GPT fast lookup `{meaning, example}` → saves word via existing save_word (with initial SM-2 review) → returns `{term, meaning, example, word_id}`. If GPT unavailable → 503 with clear message (word not saved).
3. No other backend changes; quizzes (clause_id), tutor, CEFR, vocabulary review all exist.

## Out of scope (unchanged)

- Real Google/Apple OAuth (guest login remains), TTS, final exam, PostgreSQL migration, iOS build polish.

## Acceptance

- Opening the app (guest, contract exists) lands on Journey with real progress.
- Tapping a word in Read stage shows meaning and saves it (visible later in Vocabulary).
- Completing the 3-question quiz marks the clause complete and unlocks the next.
- Tutor opens chatting with no manual session setup.
- Language toggle flips UI ar↔en with correct RTL/LTR.
- All backend tests pass; frontend widget tests updated and passing; web build succeeds.
