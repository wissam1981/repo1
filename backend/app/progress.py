"""In-memory upload/processing progress, keyed by contract id.

Single-process only (we run one uvicorn worker against SQLite); if the app
ever moves to multiple workers this should move to the database or Redis.
"""
import threading

_lock = threading.Lock()
_progress: dict[int, dict] = {}


def set_progress(contract_id: int, stage: str, done: int, total: int) -> None:
    with _lock:
        _progress[contract_id] = {"stage": stage, "done": done, "total": total}


def get_progress(contract_id: int) -> dict | None:
    with _lock:
        p = _progress.get(contract_id)
        return dict(p) if p else None


def clear_progress(contract_id: int) -> None:
    with _lock:
        _progress.pop(contract_id, None)
