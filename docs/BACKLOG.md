# Backlog — deferred items

Items intentionally deferred from earlier plans, to be handled in the plan noted.

## Auth (real provider verification) plan
- Implement real Google + Apple ID-token verification in `verify_provider_token` (currently raises `NotImplementedError`).
- Rework `auth_router._verifier` wiring: the current `def _verifier(fn=Depends(verify_provider_token)): return fn` works under the test override but would 422 in production (FastAPI treats `verify_provider_token`'s args as query params). Use a clean injectable verifier dependency that returns a `ProviderIdentity`, and add a production-path test.

## Contracts / object storage plan
- Replace the `file_url = local://<filename>` placeholder with a real S3-compatible upload of the original file.
- Add a transaction boundary + explicit error status to `upload_contract` / `split_and_explain`: on Claude failure mid-way, avoid leaving a contract marked `explained` with partial or zero clauses.
- Validate Claude's JSON output shape (e.g. via Pydantic) in `split_and_explain` before persisting, per the design's "validate structured output" intent. Today `split.get("clauses", [])` silently yields zero clauses on an unexpected shape.

## Deployment plan
- Install/provision PostgreSQL and run `alembic upgrade head` against it (skipped locally — Postgres not installed during Plan 1).
