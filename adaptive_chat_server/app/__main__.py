"""CLI entrypoint: `python -m app [--ollama-url ...] [--ollama-model ...]`.

Bridges CLI args to `app.main` via environment variables rather than passing
them through as function args, because uvicorn `--reload` re-imports
`app.main` in a fresh subprocess — env vars are the one thing that survives
that boundary.
"""
from __future__ import annotations

import argparse
import os


def main() -> None:
    parser = argparse.ArgumentParser(prog="python -m app")
    parser.add_argument(
        "--ollama-url",
        default=None,
        help="Base URL of a running Ollama server, e.g. http://localhost:11434. "
        "Omit to run the echo demo.",
    )
    parser.add_argument(
        "--ollama-model",
        default="llama3.2",
        help="Ollama model name (default: llama3.2).",
    )
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=8000)
    args = parser.parse_args()

    if args.ollama_url:
        os.environ["OLLAMA_URL"] = args.ollama_url
    os.environ["OLLAMA_MODEL"] = args.ollama_model

    import uvicorn

    uvicorn.run("app.main:app", host=args.host, port=args.port, reload=False)


if __name__ == "__main__":
    main()
