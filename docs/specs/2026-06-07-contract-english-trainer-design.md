# Contract English Trainer — Design Spec

**Date:** 2026-06-07
**Status:** Approved (architecture + data model approved by user; technical details delegated to implementer)
**Primary goal (per user):** Learn English. The contract is the vehicle; the learning loop (vocabulary + quizzes + spaced repetition + level tracking) is the heart of the product.

---

## 1. Overview

Contract English Trainer is a cross-platform app (iOS + Web first, Windows later) that helps an Arabic-speaking user strengthen English by reading and understanding real English contracts. The user uploads a contract (PDF/Word); the app breaks it into clauses, explains each in simple English (with optional Arabic), teaches vocabulary with pronunciation, quizzes the user, runs an AI tutor, and schedules vocabulary reviews using spaced repetition. Progress, CEFR level (A1–C2), and a daily plan are tracked over time.

### User journey
1. Sign in with Google or Apple.
2. Upload a contract (PDF/Word) → server extracts text and splits it into clauses.
3. For each clause: original English text + simple-English explanation + optional Arabic + key legal terms.
4. Tap any word → spoken pronunciation + meaning + example + "Save" button.
5. After each section: quizzes (multiple choice, true/false, fill-in-the-blank, open comprehension).
6. AI tutor converses with the user, corrects answers, explains mistakes, raises difficulty gradually.
7. Saved words are reviewed automatically on a spaced schedule (1 day, 3 days, 1 week, 1 month...).
8. Progress dashboard: CEFR level, saved-word count, comprehension %, daily plan.
9. On finishing a contract: final exam + summary + key clauses extraction.

---

## 2. Architecture

```
Flutter app (iOS + Web)  ── HTTPS (REST + JWT) ──>  FastAPI server (Python)
                                                      ├─> PostgreSQL  (all data)
                                                      ├─> Claude API  (all AI)
                                                      └─> Object Store (original files)
```

**Principles**
- **All AI runs on the server.** The Claude API key never reaches the client.
- **Stateless server.** All state lives in PostgreSQL; eases scaling and later Windows support (same Flutter codebase).
- **Separation of concerns.** Client renders and collects input; logic + AI live on the server.
- **Model tiering for cost.** Heavy tasks (contract analysis, AI tutor) use a stronger Claude model (Opus/Sonnet); light tasks (single-word meaning) use a faster/cheaper model (Haiku).

**Stack decisions (made by implementer per user delegation)**
- Frontend: Flutter (single codebase, iOS + Web for MVP, Windows later).
- Backend: Python FastAPI.
- Database: PostgreSQL.
- File storage: S3-compatible object store.
- Auth: Google + Apple Sign-In; server verifies provider token and issues its own JWT.
- Text extraction: `pypdf` for PDF, `python-docx` for Word.
- Text-to-speech: on-device TTS via `flutter_tts` (free, works on iOS + Web) for word pronunciation and full-contract read-aloud. No paid TTS service needed for MVP.
- Spaced repetition: SM-2 algorithm (intervals grow with each successful review: ~1d → 3d → 1w → 1m...), which matches the user's described behavior.

---

## 3. Data Model (PostgreSQL)

| Table | Purpose | Key fields |
|-------|---------|-----------|
| **users** | Accounts | `id`, `email`, `auth_provider`, `cefr_level`, `created_at` |
| **contracts** | Uploaded contracts | `id`, `user_id`, `title`, `file_url`, `status` (uploaded/parsed/explained), `created_at` |
| **clauses** | Clauses per contract | `id`, `contract_id`, `order`, `original_text`, `simple_en`, `arabic`, `key_terms` (JSON) |
| **words** | Saved vocabulary | `id`, `user_id`, `term`, `meaning`, `example`, `clause_id` (source) |
| **reviews** | Spaced-repetition schedule | `id`, `word_id`, `due_date`, `interval_days`, `ease`, `repetitions`, `last_result` |
| **quizzes** | Generated quizzes | `id`, `clause_id` or `contract_id`, `type` (mcq/tf/fill/open/final), `questions` (JSON) |
| **quiz_attempts** | User attempts | `id`, `user_id`, `quiz_id`, `answers` (JSON), `score`, `created_at` |
| **tutor_sessions** | AI tutor conversations | `id`, `user_id`, `contract_id`, `messages` (JSON), `difficulty`, `created_at` |

**Design notes**
- Saved word (`words`) is separate from review schedule (`reviews`): one review record per word evolves over time. Separates "what to learn" from "when to review."
- `key_terms`, `questions`, `messages` stored as JSON: their shape is AI-generated and variable; no complex queries needed inside them.
- `cefr_level` on the user is updated periodically from quiz performance (A1–C2 feature).

---

## 4. AI Flows (Claude API, server-side)

Each flow is a server endpoint that builds a prompt, calls Claude, validates structured JSON output, and stores the result.

1. **Analyze & split** — input: extracted contract text → output: ordered clauses.
2. **Explain clause** — input: a clause → output: simple English, optional Arabic, key legal terms with meanings.
3. **Word card** — input: a word + clause context → output: meaning + example (cheap/fast model).
4. **Generate quiz** — input: clause(s) → output: questions of the requested type (mcq/tf/fill/open).
5. **Grade answer** — input: question + user answer → output: correct/incorrect + explanation of the mistake.
6. **AI tutor turn** — input: conversation history + difficulty → output: next question or feedback; difficulty rises with success.
7. **Estimate level** — input: recent quiz_attempts → output: updated CEFR level (A1–C2).
8. **Final exam + summary** — input: whole contract → output: comprehensive exam, plain-language summary, key clauses.

All Claude calls request structured JSON; the server validates before storing. Failures return a clear error and are retried with backoff.

---

## 5. Spaced Repetition

- When a word is saved, a `reviews` record is created due immediately (or next day).
- Reviews surface due words to the user (flashcard-style: show term → recall meaning → self-grade or quiz-grade).
- On each review, SM-2 updates `interval_days`, `ease`, `repetitions`:
  - Correct → interval grows (1d → 3d → ~1w → ~1m → ...).
  - Incorrect → interval resets to short, word resurfaces soon.
- The daily plan pulls today's due reviews + new clauses to read + a quiz target.

---

## 6. Build Phasing (within one coherent plan)

To manage scope, build the core loop first, then layer the heavier features on top. All features are in scope for v1 per the user; phasing is build order, not a cut list.

- **Phase 1 — Core loop:** auth, upload + extract + split, clause explanation, word card + save + TTS, basic quizzes (mcq/tf/fill), spaced repetition, progress dashboard skeleton.
- **Phase 2 — Heavier features:** open comprehension questions + AI grading, AI tutor with rising difficulty, full-contract read-aloud, CEFR level estimation.
- **Phase 3 — Completion:** final exam, contract summary, key-clause extraction, daily plan refinement.

---

## 7. Testing Strategy

- **Backend:** unit tests for spaced-repetition math and text extraction; integration tests for each endpoint with the Claude call mocked (assert prompt shape + JSON validation + DB writes).
- **AI output:** golden-sample tests that validate structured JSON schema, not exact wording.
- **Frontend:** widget tests for key screens (clause view, word card, quiz, review); a happy-path flow test.
- **Manual:** verify upload + TTS on both iOS and Web (platform-specific behaviors).

---

## 8. Error Handling

- Upload: reject unsupported/oversized files with a clear message; show parse failures distinctly from AI failures.
- AI: retries with backoff; on persistent failure, store partial progress and let the user retry that step.
- Offline: app shows cached contracts/clauses read-only; new AI actions require connectivity.

---

## 9. Out of Scope (v1)

- Windows desktop build (same codebase, added after iOS + Web are stable).
- On-device/offline AI.
- Email/password login (Google + Apple only for v1).
- Multi-language UI beyond Arabic/English.
