# adaptive_chat_server

FastAPI echo backend for the Adaptive Chat SDUI demo.

## Run

    python3 -m venv .venv
    .venv/bin/pip install -r requirements.txt
    .venv/bin/uvicorn app.main:app --reload --port 8000

## Test

    .venv/bin/python -m pytest -v

## Ollama (optional)

By default the server runs the echo demo (every reply is `"Did you just say: ..."`).
To answer with a local [Ollama](https://ollama.com) chat model instead, start
the server via the CLI entrypoint with `--ollama-url`:

    ollama pull llama3.2   # once, if you haven't already
    ollama serve           # if it isn't already running

    .venv/bin/python -m app --ollama-url http://localhost:11434 [--ollama-model llama3.2]

Ollama must already be running locally and the model must be pulled — the
server does not start or manage Ollama itself. If Ollama is unreachable when
a message is sent, the reply falls back to a short
`"(Ollama unreachable at ...)"` message instead of failing the request.

Omit `--ollama-url` (or run `uvicorn app.main:app` directly, as in **Run**
above) to keep the echo demo. `--ollama-model` defaults to `llama3.2`.
`--host`/`--port` are also available and default to `127.0.0.1`/`8000`.
