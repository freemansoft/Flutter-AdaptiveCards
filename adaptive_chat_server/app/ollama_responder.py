"""Responder that calls a local Ollama chat model over HTTP.

Opt-in: only constructed when the server is started with `--ollama-url`
(or the `OLLAMA_URL` env var is set). Degrades gracefully to a fallback
string on connection errors so a missing/unreachable Ollama never crashes
a request.
"""
from __future__ import annotations

import httpx


class OllamaResponder:
    """Calls `POST {ollama_url}/api/chat` with the conversation history."""

    def __init__(
        self,
        ollama_url: str,
        model: str = "llama3.2",
        client: httpx.Client | None = None,
    ) -> None:
        self._ollama_url = ollama_url
        self._model = model
        self._client = client or httpx.Client(timeout=60)

    def reply(self, text: str, history: list[tuple[str, str]]) -> str:
        messages = [{"role": role, "content": content} for (role, content) in history]
        messages.append({"role": "user", "content": text})
        try:
            response = self._client.post(
                f"{self._ollama_url}/api/chat",
                json={"model": self._model, "messages": messages, "stream": False},
            )
            response.raise_for_status()
            return response.json()["message"]["content"]
        except httpx.HTTPError:
            return f"(Ollama unreachable at {self._ollama_url})"
