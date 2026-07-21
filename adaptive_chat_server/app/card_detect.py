"""Decide whether a model reply is *only* an Adaptive Card, and extract its body.

The Ollama model answers either in plain markdown (rendered in a TextBlock bubble)
or, when the card system prompt is active, with an Adaptive Card fragment we embed
in the assistant bubble. This module decides which — strictly: the *entire* reply
(after stripping an optional code fence) must be the card, or it is treated as text.
"""
from __future__ import annotations

import json
import re

# Matches a whole reply wrapped in a ```json ... ``` (or bare ```) fence.
_FENCE = re.compile(r"^\s*```(?:json)?\s*(.*?)\s*```\s*$", re.DOTALL | re.IGNORECASE)


def _strip_fence(raw: str) -> str:
    match = _FENCE.match(raw)
    return match.group(1) if match else raw.strip()


def try_parse_card_body(raw: str) -> list | None:
    """Return Adaptive Card body items if ``raw`` is *only* a card, else None.

    Accepts either a full ``{"type": "AdaptiveCard", "body": [...]}`` object or a
    bare, non-empty JSON array of objects (a body fragment). Surrounding prose,
    invalid JSON, a non-card object, a scalar, or an array containing non-objects
    all yield None so the caller falls back to a text reply.
    """
    text = _strip_fence(raw)
    try:
        parsed = json.loads(text)
    except ValueError:
        return None
    if isinstance(parsed, list):
        if parsed and all(isinstance(item, dict) for item in parsed):
            return parsed
        return None
    if (
        isinstance(parsed, dict)
        and parsed.get("type") == "AdaptiveCard"
        and isinstance(parsed.get("body"), list)
    ):
        return parsed["body"]
    return None
