"""Server-authored Adaptive Card bubbles and the response envelope.

All bubble alignment and fill live here, in the card JSON, so the client
stays 'dumb' and renders each card full-width and stacked.
"""
from __future__ import annotations

from app.store import Message

_VERSION = "1.5"


def _text_container(text: str, style: str) -> dict:
    return {
        "type": "Container",
        "style": style,
        "roundedCorners": True,
        "items": [{"type": "TextBlock", "text": text, "wrap": True}],
    }


def _bubble(text: str, *, style: str, align_right: bool) -> dict:
    content = {"type": "Column", "width": "auto", "items": [_text_container(text, style)]}
    spacer = {"type": "Column", "width": "stretch", "items": []}
    columns = [spacer, content] if align_right else [content, spacer]
    return {
        "type": "AdaptiveCard",
        "version": _VERSION,
        "body": [{"type": "ColumnSet", "columns": columns}],
    }


def user_bubble(text: str) -> dict:
    """Right-aligned accent bubble for the user's message."""
    return _bubble(text, style="accent", align_right=True)


def assistant_bubble(text: str) -> dict:
    """Left-aligned emphasis bubble for the assistant's reply."""
    return _bubble(text, style="emphasis", align_right=False)


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
