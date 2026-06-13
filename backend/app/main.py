from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.db import Base, _factory
from app.routers import (
    auth_router,
    contracts_router,
    quizzes_router,
    tutor_router,
    vocabulary_router,
)
from app import models  # noqa: F401

app = FastAPI(title="Contract English Trainer")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Create all tables on startup
engine = _factory().kw['bind']
Base.metadata.create_all(engine)

# Tiny additive migrations: create_all does not add new columns to existing
# tables, so add any missing clause columns when upgrading an older database.
# The PRAGMA-based column check is SQLite-only; on Postgres (Cloud Run)
# create_all already builds the full schema, so we skip it there.
with engine.connect() as _conn:
    from sqlalchemy import text as _text
    if engine.dialect.name == "sqlite":
        cols = [row[1]
                for row in _conn.execute(_text("PRAGMA table_info(clauses)"))]
        _new_cols = {
            "completed_at": "DATETIME",
            "is_definition": "BOOLEAN DEFAULT 0",
            "related_orders": "JSON",
        }
        if cols:
            for _name, _type in _new_cols.items():
                if _name not in cols:
                    _conn.execute(
                        _text(f"ALTER TABLE clauses ADD COLUMN {_name} {_type}"))
            _conn.commit()
    # Background processing dies with the process: any contract still marked
    # 'processing' at boot is orphaned — fail it so clients stop waiting.
    _conn.execute(_text(
        "UPDATE contracts SET status='failed' WHERE status='processing'"))
    _conn.commit()

app.include_router(auth_router.router)
app.include_router(contracts_router.router)
app.include_router(vocabulary_router.router)
app.include_router(quizzes_router.router)
app.include_router(tutor_router.router)


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}
