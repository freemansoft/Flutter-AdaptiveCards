"""Reply strategies. v1 echoes; a future OllamaResponder drops in here."""
from __future__ import annotations

from typing import Protocol


class Responder(Protocol):
    """Turns a user message into a reply string."""

    def reply(self, text: str) -> str: ...


class EchoResponder:
    """v1 responder: echoes the user's text back."""

    def reply(self, text: str) -> str:
        return f"Did you just say: {text}"
