"""Assembles the ``GET /status`` payload from the store and the live responder.

Deliberately carries no message text: the endpoint is unauthenticated and CORS
is wide open, so conversation content must not be reachable through it. What it
does report is volume (how many conversations, how many turns, how many tokens)
and the effective configuration the process is actually running.
"""
from __future__ import annotations

import hashlib

from app.stats import to_dict
from app.store import Conversation, ConversationStore


def conversation_ref(conversation_id: str) -> str:
    """Stable, non-reversible label for correlating a conversation across polls.

    An operator watching ``/status`` over time needs some way to tell "this is
    the same conversation as last poll" without the raw ``conversationId`` —
    that id is also the bearer credential for
    ``GET/POST /conversations/{cid}/interactions``, which return message text.
    Since this endpoint is unauthenticated and CORS is wide open, leaking the
    id here would hand any web page the developer visits a way to read the
    transcript. Truncating the hash keeps it short for a status table while
    leaving it useless for guessing the original id.
    """
    return hashlib.sha256(conversation_id.encode()).hexdigest()[:12]


def _describe_responder(responder: object) -> dict:
    """Effective responder config, or a placeholder when it cannot report one.

    Tests swap in stubs via ``monkeypatch.setattr("app.main.responder", ...)``
    that need not implement the full protocol. A stub must not be able to turn
    /status into a 500, so a missing ``describe`` degrades instead of raising.
    """
    describe = getattr(responder, "describe", None)
    if not callable(describe):
        return {"kind": "unknown"}
    return describe()


def _conversation_row(conversation: Conversation) -> dict:
    """One conversation's volume: turn count, cumulative tokens, last turn."""
    prompt_tokens = 0
    reply_tokens = 0
    for iid in conversation.order:
        stats = conversation.interactions[iid].stats
        if stats is not None:
            prompt_tokens += stats.prompt_tokens
            reply_tokens += stats.reply_tokens

    last: dict | None = None
    if conversation.order:
        last_iid = conversation.order[-1]
        last_stats = conversation.interactions[last_iid].stats
        last = {
            # No interaction id here: "lastInteraction" already identifies
            # which turn this is (the most recent one), so the id adds
            # nothing an operator needs, and it would be one more identifier
            # the endpoint didn't need to expose.
            # None when that turn cost nothing measurable — echo mode or an
            # Ollama failure. The turn still counts toward interactionCount.
            "stats": to_dict(last_stats) if last_stats is not None else None,
        }

    return {
        # Named "conversationRef", not "conversationId": the value is a
        # truncated hash, not the real id, and keeping the old key name would
        # invite a caller to try using it against the transcript endpoints.
        "conversationRef": conversation_ref(conversation.conversation_id),
        "interactionCount": len(conversation.order),
        "totals": {
            "promptTokens": prompt_tokens,
            "replyTokens": reply_tokens,
            "totalTokens": prompt_tokens + reply_tokens,
        },
        "lastInteraction": last,
    }


def build_status(store: ConversationStore, responder: object) -> dict:
    """Operator snapshot of the running server.

    ``responder`` is typed loosely because the route passes the module-level
    singleton, which tests replace with stubs; only ``describe()`` is used.
    """
    conversations = store.list_conversations()
    return {
        "responder": _describe_responder(responder),
        "conversationCount": len(conversations),
        "conversations": [_conversation_row(c) for c in conversations],
    }
