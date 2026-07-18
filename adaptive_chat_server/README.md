# adaptive_chat_server

FastAPI echo backend for the Adaptive Chat SDUI demo.

## Run

    python3 -m venv .venv
    .venv/bin/pip install -r requirements.txt
    .venv/bin/uvicorn app.main:app --reload --port 8000

## Test

    .venv/bin/python -m pytest -v
