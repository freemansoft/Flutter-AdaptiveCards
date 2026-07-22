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


def _full_width_bubble(items: list, *, style: str) -> dict:
    """A single full-width styled container — no ColumnSet, so it spans the row.

    Used for card replies. The 75% ``_bubble`` layout relies on ``ColumnSet``,
    whose columns are wrapped in ``IntrinsicHeight`` by the renderer; a
    ``Carousel`` inside gates its subtree behind a ``LayoutBuilder`` that cannot
    answer the intrinsic-height pass, so the card renders blank / asserts. Until
    the core Carousel is made intrinsic-safe, card replies skip the ColumnSet and
    render full-width (structured content benefits from the extra width anyway).
    """
    container = {
        "type": "Container",
        "style": style,
        "roundedCorners": True,
        "items": items,
    }
    return {"type": "AdaptiveCard", "version": _VERSION, "body": [container]}


def _text_items(text: str) -> list:
    return [{"type": "TextBlock", "text": text, "wrap": True}]


def user_bubble(text: str) -> dict:
    """Right-aligned accent bubble for the user's message."""
    return _bubble(_text_items(text), style="accent", align_right=True)


def assistant_bubble(text: str) -> dict:
    """Left-aligned emphasis bubble for a Markdown text assistant reply.

    The ``TextBlock`` renders GitHub-flavored Markdown, so this is the
    default reply shape used before the card path existed.
    """
    return _bubble(_text_items(text), style="emphasis", align_right=False)


def assistant_card_bubble(body_items: list) -> dict:
    """Full-width emphasis container holding a model card fragment.

    Unlike the text bubbles, a card reply renders full-width with no ``ColumnSet``
    (see :func:`_full_width_bubble`): the model may return a ``Carousel``, and the
    renderer's ``ColumnSet`` -> ``IntrinsicHeight`` cannot lay out the Carousel's
    ``LayoutBuilder``, so the card would render blank. Same emphasis fill and
    rounded corners as a text reply; the detected body items become the
    container's contents. This is a sample-side workaround pending the core
    Carousel intrinsic-height fix.
    """
    return _full_width_bubble(body_items, style="emphasis")


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
