"""Per-interaction Ollama usage: token counts plus where the time went.

Ollama returns these numbers on every ``/api/chat`` response and the server
previously discarded all but one of them. Capturing them makes "what did that
turn cost" and "how large has this conversation grown" answerable after the
fact, via ``GET /status``.
"""
from __future__ import annotations

from dataclasses import dataclass

# Ollama reports every duration in nanoseconds. Convert once, here, so no
# downstream caller has to remember the unit.
_NS_PER_MS = 1_000_000


@dataclass(frozen=True)
class InteractionStats:
    """What one Ollama turn cost: tokens in and out, plus the timing breakdown.

    Stores only what Ollama reported. Derived figures (total tokens, generation
    speed) are computed in :func:`to_dict` so this record stays a faithful copy.
    """

    prompt_tokens: int  # Ollama prompt_eval_count — tokens sent
    reply_tokens: int  # Ollama eval_count — tokens generated
    total_ms: int  # total_duration
    load_ms: int  # load_duration — model load, ~0 when already warm
    prompt_eval_ms: int  # prompt_eval_duration — time reading the prompt
    eval_ms: int  # eval_duration — time generating


def _ms(data: dict, key: str) -> int:
    """Nanosecond field as whole milliseconds; 0 when absent or not an int."""
    value = data.get(key)
    if not isinstance(value, int):
        return 0
    return value // _NS_PER_MS


def from_ollama_response(data: dict) -> InteractionStats | None:
    """Build stats from an Ollama ``/api/chat`` body, or ``None`` if unusable.

    Both token counts are required: a record without them answers no question
    worth asking, so a body missing them yields ``None`` rather than a
    half-filled record. Durations are supplementary — a missing or malformed one
    defaults to 0 instead of discarding usable token counts. Never raises, so a
    misbehaving Ollama cannot break a request.
    """
    prompt_tokens = data.get("prompt_eval_count")
    reply_tokens = data.get("eval_count")
    if not isinstance(prompt_tokens, int) or not isinstance(reply_tokens, int):
        return None
    return InteractionStats(
        prompt_tokens=prompt_tokens,
        reply_tokens=reply_tokens,
        total_ms=_ms(data, "total_duration"),
        load_ms=_ms(data, "load_duration"),
        prompt_eval_ms=_ms(data, "prompt_eval_duration"),
        eval_ms=_ms(data, "eval_duration"),
    )


def to_dict(stats: InteractionStats) -> dict:
    """Serialize for the ``/status`` payload, deriving totals and speed.

    ``tokensPerSecond`` is generation speed (reply tokens over generation time),
    not end-to-end throughput — it excludes model load and prompt evaluation, so
    it stays comparable across warm and cold turns. Zero when ``eval_ms`` is 0.
    """
    tokens_per_second = 0.0
    if stats.eval_ms > 0:
        tokens_per_second = round(stats.reply_tokens / (stats.eval_ms / 1000), 1)
    return {
        "promptTokens": stats.prompt_tokens,
        "replyTokens": stats.reply_tokens,
        "totalTokens": stats.prompt_tokens + stats.reply_tokens,
        "totalMs": stats.total_ms,
        "loadMs": stats.load_ms,
        "promptEvalMs": stats.prompt_eval_ms,
        "evalMs": stats.eval_ms,
        "tokensPerSecond": tokens_per_second,
    }
