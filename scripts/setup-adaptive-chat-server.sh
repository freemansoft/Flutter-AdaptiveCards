#!/bin/sh
# Creates adaptive_chat_server/.venv and installs its requirements if missing.
# Requires Python 3.10+: FastAPI evaluates PEP 604 `X | None` type hints at
# runtime, which raises `TypeError: Unable to evaluate type annotation` on 3.9
# and older.
set -e
cd "$(dirname "$0")/../adaptive_chat_server"

version_ok() {
  "$1" -c 'import sys; sys.exit(0 if sys.version_info >= (3, 10) else 1)' 2>/dev/null
}

find_python() {
  for candidate in python3.13 python3.12 python3.11 python3.10 python3; do
    if command -v "$candidate" >/dev/null 2>&1 && version_ok "$candidate"; then
      command -v "$candidate"
      return 0
    fi
  done
  return 1
}

if [ ! -x .venv/bin/python ]; then
  PYTHON=$(find_python) || {
    echo "adaptive_chat_server: no Python 3.10+ interpreter found on PATH." >&2
    echo "  FastAPI evaluates 'str | None' style type hints at runtime, which" >&2
    echo "  fails on Python 3.9 and older. Install a newer Python, e.g.:" >&2
    echo "    brew install python@3.12" >&2
    exit 1
  }
  echo "adaptive_chat_server: using $("$PYTHON" --version) ($PYTHON)"
  "$PYTHON" -m venv .venv
  .venv/bin/pip install -q -r requirements.txt
  echo "adaptive_chat_server: .venv created and requirements installed"
else
  if ! version_ok .venv/bin/python; then
    echo "adaptive_chat_server: existing .venv uses $(.venv/bin/python --version), which is older than 3.10." >&2
    echo "  Delete adaptive_chat_server/.venv and re-run this task to rebuild it with a newer Python." >&2
    exit 1
  fi
  echo "adaptive_chat_server: .venv already present"
fi