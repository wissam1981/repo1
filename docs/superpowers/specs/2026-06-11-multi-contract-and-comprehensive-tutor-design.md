# Multi-Contract + Comprehensive Tutor + Guest-Only Login — Spec

**Date:** 2026-06-11 · **Approved:** user (with gpt-4o tutor cost accepted)

## 1. Guest-only login (interim)
Remove the disabled Google/Apple buttons. Login = icon, title, subtitle, one
gold "Continue as Guest" button, language toggle. Real OAuth deferred.

## 2. Multiple contracts
- ContractsProvider gains an *active contract* (defaults to first; switchable).
- Journey: contract title becomes a popup menu listing all contracts
  (check on active) + an "upload new" item; persistent (+) FAB uploads more
  contracts through the existing progress dialog.
- Tutor and Progress screens follow the active contract.
- Backend unchanged (list/upload/progress already per-contract).

## 3. Comprehensive bilingual tutor
- Context: FULL text of every clause (was: first 50 chars!) + a definitions
  glossary, capped at ~50K chars, + last 10 messages.
- Prompt: answer in the SAME language as the student's question (Arabic or
  English); comprehensive, cites clause numbers; corrects mistakes; adapts
  difficulty 1-5. JSON {message, new_difficulty} unchanged.
- Model: gpt-4o (default path). Accepted cost ≈ $0.03-0.05/question.
- Frontend: chat bubbles auto-detect Arabic → RTL rendering.

## Acceptance
- Login shows only guest button. Uploading a 2nd contract works with progress;
  switcher swaps journeys. Arabic question → thorough Arabic answer citing
  clause numbers; English → English. All tests pass; web + iPhone deployed.
