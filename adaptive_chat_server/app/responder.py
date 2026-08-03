"""Reply strategies and the value type they return."""
from __future__ import annotations

from dataclasses import dataclass
from typing import Protocol

from app.stats import InteractionStats


@dataclass(frozen=True)
class Reply:
    """A responder's answer: raw text (for history) plus an optional card body.

    ``text`` is always the model's raw output and is what threads into Ollama
    conversation history. ``card_body`` holds the parsed Adaptive Card body items
    when the reply is *only* a card (rendered inside the assistant bubble); ``None``
    means render ``text`` as a Markdown text bubble (a ``TextBlock``, which
    supports GitHub-flavored Markdown).

    ``stats`` carries the responder's token/timing usage for this turn, or
    ``None`` when the reply cost nothing measurable (echo mode, or any failure
    path). It never affects what the user sees — it exists for ``GET /status``.
    """

    text: str
    card_body: list | None = None
    stats: InteractionStats | None = None


class Responder(Protocol):
    """Turns a user message (plus prior turns) into a :class:`Reply`."""

    def reply(self, text: str, history: list[tuple[str, str]]) -> Reply: ...

    def describe(self) -> dict:
        """Effective configuration of this responder, for ``GET /status``.

        Reports what the process is *actually* running, not what it was asked
        for — a responder may resolve or downgrade its own settings at
        construction, and it is the only component that knows the difference.
        Keys are camelCase because the result is served verbatim as JSON.
        """
        ...


class EchoResponder:
    """v1 responder: echoes the user's text back. Ignores history; never a card."""

    def reply(self, text: str, history: list[tuple[str, str]]) -> Reply:
        return Reply(text=f"Did you just say: {text}")

    def describe(self) -> dict:
        return {"kind": "echo"}
