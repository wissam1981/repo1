from datetime import datetime, timezone

from fastapi import (
    APIRouter,
    BackgroundTasks,
    Depends,
    File,
    Form,
    HTTPException,
    UploadFile,
    status,
)
from sqlalchemy.orm import Session

from app.claude_client import ClaudeClient
from app.deps import get_claude, get_current_user
from app.db import _factory, get_db
from app.extraction import extract_text, UnsupportedFileError
from app.models import Clause, Contract, User
from app.progress import clear_progress, get_progress, set_progress
from app.schemas import ClauseOut, ContractOut
from app.services.contracts import split_and_explain

router = APIRouter(prefix="/contracts", tags=["contracts"])


def _process_contract(contract_id: int, text: str, claude: ClaudeClient) -> None:
    """Background processing: split + explain with progress reporting.

    Runs after the upload response returns, with its own DB session.
    """
    db = _factory()()
    try:
        contract = db.get(Contract, contract_id)
        if contract is None:
            return
        split_and_explain(
            db, claude, contract, text,
            on_progress=lambda stage, done, total: set_progress(
                contract_id, stage, done, total),
        )
        set_progress(contract_id, "done", 1, 1)
    except Exception:
        # Mark failure so the client stops polling with a clear state.
        set_progress(contract_id, "failed", 0, 1)
        try:
            contract = db.get(Contract, contract_id)
            if contract is not None:
                contract.status = "failed"
                db.commit()
        except Exception:
            pass
    finally:
        db.close()


@router.get("", response_model=list[ContractOut])
def list_contracts(
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
) -> list[Contract]:
    """List all contracts for the current user."""
    contracts = db.query(Contract).filter_by(user_id=user.id).all()
    return contracts


@router.post("", response_model=ContractOut, status_code=status.HTTP_201_CREATED)
def upload_contract(
    background: BackgroundTasks,
    title: str = Form(...),
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    claude: ClaudeClient = Depends(get_claude),
    user: User = Depends(get_current_user),
) -> Contract:
    data = file.file.read()
    try:
        text = extract_text(data, file.filename or "")
    except UnsupportedFileError as exc:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, str(exc))
    if not text.strip():
        raise HTTPException(
            status.HTTP_400_BAD_REQUEST,
            "Could not extract any text from this file",
        )

    contract = Contract(user_id=user.id, title=title,
                        file_url=f"local://{file.filename}",
                        status="processing")
    db.add(contract)
    db.commit()
    db.refresh(contract)

    # Heavy AI work happens in the background; the client polls /progress.
    set_progress(contract.id, "queued", 0, 1)
    background.add_task(_process_contract, contract.id, text, claude)
    return contract


@router.get("/{contract_id}/progress")
def contract_progress(
    contract_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
) -> dict:
    """Processing progress for the upload UI: stage, counts and percent."""
    contract = db.get(Contract, contract_id)
    if contract is None or contract.user_id != user.id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Not found")

    p = get_progress(contract_id)
    if p is None:
        # No in-flight processing — report the stored final state.
        done_states = {"explained": 100, "parsed": 100, "failed": 0}
        percent = done_states.get(contract.status, 0)
        return {"status": contract.status, "stage": contract.status,
                "done": 0, "total": 0, "percent": percent}

    percent = int(p["done"] / p["total"] * 100) if p["total"] else 0
    if p["stage"] in ("done", "failed"):
        clear_progress(contract_id)
        percent = 100 if p["stage"] == "done" else 0
    return {"status": contract.status, "stage": p["stage"],
            "done": p["done"], "total": p["total"], "percent": percent}


@router.get("/{contract_id}", response_model=ContractOut)
def get_contract(
    contract_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
) -> Contract:
    contract = db.get(Contract, contract_id)
    if contract is None or contract.user_id != user.id:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Not found")
    return contract


@router.post(
    "/{contract_id}/clauses/{clause_id}/complete",
    response_model=ClauseOut,
)
def complete_clause(
    contract_id: int,
    clause_id: int,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
) -> Clause:
    """Mark a clause as completed in the user's learning journey."""
    clause = db.get(Clause, clause_id)
    if (
        clause is None
        or clause.contract_id != contract_id
        or clause.contract.user_id != user.id
    ):
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Clause not found")
    if clause.completed_at is None:
        clause.completed_at = datetime.now(timezone.utc)
        db.commit()
        db.refresh(clause)
    return clause
