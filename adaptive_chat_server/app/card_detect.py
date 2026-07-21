"""Decide whether a model reply is *only* an Adaptive Card, and extract its body.

The Ollama model answers either in plain markdown (rendered in a TextBlock bubble)
or, when the card system prompt is active, with an Adaptive Card fragment we embed
in the assistant bubble. This module decides which: the *entire* reply (after
stripping an optional code fence) must be the card, or it is treated as text.

Three fragment shapes are accepted, because local models emit all three:
  1. a full card object   ``{"type": "AdaptiveCard", "body": [ ... ]}``  -> its body
  2. a bare array          ``[ {...}, {...} ]``                           -> as-is
  3. a single element      ``{"type": "Input.ChoiceSet", ...}``          -> ``[element]``
A dict with no ``type`` string, a scalar, or an empty/mixed array is treated as text.

Leading/trailing decoration a model wraps around the JSON — surrounding
whitespace, a code fence, or delimiter runs like ``=== `` / ``---`` / ``###`` —
is stripped before parsing. Surrounding *prose* is not: a reply with words
before or after the JSON is still treated as text.
"""
from __future__ import annotations

import json
import re

# Matches a whole reply wrapped in a ```json ... ``` (or bare ```) fence.
_FENCE = re.compile(r"^\s*```(?:json)?\s*(.*?)\s*```\s*$", re.DOTALL | re.IGNORECASE)

# Leading/trailing DECORATION a local model wraps around the JSON: whitespace and
# runs of section/Markdown delimiters (===, ---, ###, ***, ___, ~~~). Stripped
# from both ends only; the pattern halts at the first content char (e.g. { or [),
# so JSON is never clipped. Real prose words carry none of these chars at the very
# edge, so a prose-wrapped reply is left intact and still fails JSON parsing.
_DECORATION = re.compile(r"^[\s=\-#*_~]+|[\s=\-#*_~]+$")


def _strip_fence(raw: str) -> str:
    match = _FENCE.match(raw)
    return match.group(1) if match else raw.strip()


def _strip_decoration(text: str) -> str:
    return _DECORATION.sub("", text)


def try_parse_card_body(raw: str) -> list | None:
    """Return Adaptive Card body items if ``raw`` is *only* a card, else None.

    Accepts a full ``{"type": "AdaptiveCard", "body": [...]}`` object (returns its
    body), a bare non-empty JSON array of objects (returned as-is), or a single
    body-element object such as ``{"type": "Input.ChoiceSet", ...}`` (wrapped as a
    one-item body). Leading/trailing decoration (whitespace, a code fence, or
    delimiter runs such as ``=== ``) is stripped first. Surrounding prose, invalid
    JSON, a dict with no ``type``, a scalar, an empty array, or an array with
    non-objects all yield None so the caller falls back to a text reply.
    """
    text = _strip_decoration(_strip_fence(raw))
    try:
        parsed = json.loads(text)
    except ValueError:
        return None
    if isinstance(parsed, list):
        if parsed and all(isinstance(item, dict) for item in parsed):
            return parsed
        return None
    if isinstance(parsed, dict):
        if parsed.get("type") == "AdaptiveCard":
            body = parsed.get("body")
            # A full card must carry a non-empty body list; an empty/absent body
            # is nothing to render, so fall through to a text reply.
            return body if isinstance(body, list) and body else None
        # A single body element (e.g. the model emitted just an Input.ChoiceSet
        # or a TextBlock). Any object with a non-empty string ``type`` is a valid
        # element; wrap it as a one-item body fragment.
        element_type = parsed.get("type")
        if isinstance(element_type, str) and element_type:
            return [parsed]
    return None
