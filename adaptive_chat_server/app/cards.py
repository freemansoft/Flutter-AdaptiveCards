"""Server-authored Adaptive Card bubbles and the response envelope.

All bubble alignment and fill live here, in the card JSON, so the client
stays 'dumb' and renders each card full-width and stacked.
"""
from __future__ import annotations

from app.store import Message

_VERSION = "1.5"

# Chat bubbles span ~75% of the row: weighted columns 3:1 (= 75% / 25%). The
# empty spacer column pushes the bubble to one side, so a send bubble sits in
# the right 75% and a receive bubble in the left 75% (non-overlapping per row).
_BUBBLE_WEIGHT = 3
_SPACER_WEIGHT = 1


def _bubble(items: list, *, style: str, align_right: bool) -> dict:
    container = {
        "type": "Container",
        "style": style,
        "roundedCorners": True,
        "items": items,
    }
    content = {"type": "Column", "width": _BUBBLE_WEIGHT, "items": [container]}
    spacer = {"type": "Column", "width": _SPACER_WEIGHT, "items": []}
    columns = [spacer, content] if align_right else [content, spacer]
    return {
        "type": "AdaptiveCard",
        "version": _VERSION,
        "body": [{"type": "ColumnSet", "columns": columns}],
    }


def _text_items(text: str) -> list:
    return [{"type": "TextBlock", "text": text, "wrap": True}]


def user_bubble(text: str) -> dict:
    """Right-aligned accent bubble for the user's message."""
    return _bubble(_text_items(text), style="accent", align_right=True)


def assistant_bubble(text: str) -> dict:
    """Left-aligned emphasis bubble for a plain-text assistant reply."""
    return _bubble(_text_items(text), style="emphasis", align_right=False)


def assistant_card_bubble(body_items: list) -> dict:
    """Left-aligned emphasis bubble whose container holds a model card fragment.

    Same chrome as a text reply (alignment, rounded corners, emphasis fill); the
    detected Adaptive Card body items become the container's contents, so a
    returned date picker / choice set reads as living inside a chat bubble.
    """
    return _bubble(body_items, style="emphasis", align_right=False)


def envelope(cid: str, iid: str, messages: list[Message]) -> dict:
    """Wire envelope: pre-styled cards plus self/postNext links."""
    return {
        "conversationId": cid,
        "interactionId": iid,
        "messages": [m.card for m in messages],
        "links": {
            "self": f"/conversations/{cid}/interactions/{iid}",
            "postNext": f"/conversations/{cid}/interactions",
        },
    }
