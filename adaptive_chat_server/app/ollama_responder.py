"""Responder that calls a local Ollama chat model over HTTP.

Opt-in: only constructed when the server is started with `--ollama-url`
(or the `OLLAMA_URL` env var is set). Never raises to the caller — on any
failure it logs the full context (see the server console) and returns a short
diagnostic string, so a missing/unreachable/misconfigured Ollama never crashes
a request.
"""
from __future__ import annotations

import logging

import httpx

# uvicorn installs a handler on the "uvicorn.error" logger, so these messages
# appear in the server console when running via `python -m app` / uvicorn.
logger = logging.getLogger("uvicorn.error")

# Single source of truth for the fallback model name; the CLI (`--ollama-model`)
# and env (`OLLAMA_MODEL`) override it.
DEFAULT_OLLAMA_MODEL = "llama3.2"


class OllamaResponder:
    """Calls `POST {ollama_url}/api/chat` with the conversation history."""

    def __init__(
        self,
        ollama_url: str,
        model: str = DEFAULT_OLLAMA_MODEL,
        client: httpx.Client | None = None,
    ) -> None:
        self._ollama_url = ollama_url
        self._model = model
        self._client = client or httpx.Client(timeout=60)

    def reply(self, text: str, history: list[tuple[str, str]]) -> str:
        messages = [{"role": role, "content": content} for (role, content) in history]
        messages.append({"role": "user", "content": text})
        endpoint = f"{self._ollama_url}/api/chat"
        payload = {"model": self._model, "messages": messages, "stream": False}
        logger.info(
            "Ollama request: POST %s (model=%s, %d messages)",
            endpoint,
            self._model,
            len(messages),
        )

        # 1. Transport failure — never even got a response (connection refused,
        #    DNS, timeout, TLS). This is the real "unreachable" case.
        try:
            response = self._client.post(endpoint, json=payload)
        except httpx.HTTPError as exc:
            logger.error(
                "Ollama CONNECTION FAILED: %s: %s\n"
                "  endpoint=%s model=%s\n"
                "  Is `ollama serve` running and listening there? On macOS, "
                "`localhost` can resolve to IPv6 (::1) while Ollama binds IPv4 "
                "127.0.0.1 — try --ollama-url http://127.0.0.1:11434.",
                type(exc).__name__,
                exc,
                endpoint,
                self._model,
                exc_info=True,
            )
            return (
                f"(Ollama unreachable at {self._ollama_url} — "
                f"{type(exc).__name__}: {exc})"
            )

        # 2. Reached Ollama but it returned an error status (e.g. 404 when the
        #    model isn't pulled). Connected, so NOT "unreachable".
        if response.status_code >= 400:
            body = response.text[:1000]
            logger.error(
                "Ollama HTTP %s for %s (model=%s):\n  %s\n"
                "  A 404 usually means the model isn't pulled — run "
                "`ollama pull %s`.",
                response.status_code,
                endpoint,
                self._model,
                body,
                self._model,
            )
            return (
                f"(Ollama error HTTP {response.status_code} at "
                f"{self._ollama_url}: {body})"
            )

        # 3. 2xx but an unexpected body shape.
        try:
            data = response.json()
            return data["message"]["content"]
        except (ValueError, KeyError, TypeError) as exc:
            logger.error(
                "Ollama response could not be parsed (%s: %s):\n  %s",
                type(exc).__name__,
                exc,
                response.text[:1000],
                exc_info=True,
            )
            return f"(Ollama returned an unexpected response: {type(exc).__name__})"
