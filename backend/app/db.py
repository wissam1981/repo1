from collections.abc import Iterator
from sqlalchemy import create_engine, event
from sqlalchemy.orm import DeclarativeBase, Session, sessionmaker

from app.config import get_settings


class Base(DeclarativeBase):
    pass


_session_factory: sessionmaker | None = None


def _factory() -> sessionmaker:
    global _session_factory
    if _session_factory is None:
        url = get_settings().database_url
        is_sqlite = url.startswith("sqlite")
        # In-memory SQLite ("sqlite://" or ":memory:") does not support WAL.
        is_file_sqlite = is_sqlite and ":memory:" not in url and url != "sqlite://"

        connect_args = {}
        if is_sqlite:
            # Allow the connection to be used across threads (FastAPI runs sync
            # endpoints in a threadpool) and wait instead of failing when the
            # DB is briefly locked.
            connect_args = {"check_same_thread": False, "timeout": 30}
        engine = create_engine(url, future=True, connect_args=connect_args)

        if is_file_sqlite:
            @event.listens_for(engine, "connect")
            def _set_sqlite_pragma(dbapi_conn, _record):  # pragma: no cover
                # WAL lets readers and a writer coexist; busy_timeout makes
                # writers wait for a lock instead of erroring immediately.
                # Best-effort: never let pragma setup crash a connection.
                cur = dbapi_conn.cursor()
                try:
                    cur.execute("PRAGMA journal_mode=WAL")
                    cur.execute("PRAGMA busy_timeout=30000")
                except Exception:
                    pass
                finally:
                    cur.close()

        _session_factory = sessionmaker(bind=engine, expire_on_commit=False, future=True)
    return _session_factory


def get_db() -> Iterator[Session]:
    db = _factory()()
    try:
        yield db
    finally:
        db.close()
