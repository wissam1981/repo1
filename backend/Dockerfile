# Production image for the Contract English Trainer backend.
# Designed for Google Cloud Run (and any container host): binds to $PORT,
# installs only runtime deps, ships the reference corpus + official glossary.
FROM python:3.12-slim

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /app

# Install dependencies first (better layer caching). We install the project
# in non-editable mode from pyproject.toml.
COPY pyproject.toml ./
RUN pip install --upgrade pip && pip install .

# Application code, reference corpus and glossary data.
COPY app ./app

# Cloud Run sets $PORT (default 8080). A single worker is intentional: the
# upload-progress store and audio cache live in-process (see app/progress.py),
# so multiple workers would split that state. One worker handles a closed
# group fine; scale by raising Cloud Run concurrency, not worker count.
ENV PORT=8080
EXPOSE 8080
CMD ["sh", "-c", "uvicorn app.main:app --host 0.0.0.0 --port ${PORT} --workers 1"]
