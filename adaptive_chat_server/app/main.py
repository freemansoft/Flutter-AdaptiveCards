"""FastAPI entrypoint for the Adaptive Chat backend (echo or Ollama responder)."""
from __future__ import annotations

import logging
import os

from fastapi import FastAPI, Header, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware

from app.cards import assistant_bubble, assistant_card_bubble, envelope, user_bubble
from app.ollama_responder import (
    DEFAULT_HISTORY_TURNS,
    DEFAULT_NUM_CTX,
    DEFAULT_OLLAMA_MODEL,
    OllamaResponder,
)
from app.responder import EchoResponder, Responder
from app.store import ConversationStore, Interaction, Message

logger = logging.getLogger("uvicorn.error")


def _int_env(name: str, default: int) -> int:
    """Read an int env var, falling back to ``default`` on absence or bad value.

    Never raises — a malformed value logs a warning and uses the default so a
    typo in configuration cannot crash the server at import time.
    """
    raw = os.environ.get(name)
    if raw is None:
        return default
    try:
        return int(raw)
    except ValueError:
        logger.warning("Invalid %s=%r; using default %d.", name, raw, default)
        return default


app = FastAPI(title="Adaptive Chat Server")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


def build_responder(
    ollama_url: str | None,
    model: str,
    system_prompt_file: str | None = None,
    num_ctx: int = DEFAULT_NUM_CTX,
    history_turns: int = DEFAULT_HISTORY_TURNS,
) -> Responder:
    """Selects the responder for this process: Ollama if a URL is set, else echo."""
    if ollama_url:
        logger.info(
            "Responder: OllamaResponder (url=%s, model=%s, system_prompt=%s, "
            "num_ctx=%d, history_turns=%d)",
            ollama_url,
            model,
            system_prompt_file or "default",
            num_ctx,
            history_turns,
        )
        return OllamaResponder(
            ollama_url,
            model,
            system_prompt_file=system_prompt_file,
            num_ctx=num_ctx,
            history_turns=history_turns,
        )
    logger.info("Responder: EchoResponder (no --ollama-url / OLLAMA_URL set)")
    return EchoResponder()


store = ConversationStore()
# Built from env vars (not CLI args directly) so the choice survives uvicorn
# `--reload`, which re-imports this module in a fresh subprocess.
responder = build_responder(
    os.environ.get("OLLAMA_URL"),
    os.environ.get("OLLAMA_MODEL", DEFAULT_OLLAMA_MODEL),
    os.environ.get("OLLAMA_SYSTEM_PROMPT_FILE"),
    num_ctx=_int_env("OLLAMA_NUM_CTX", DEFAULT_NUM_CTX),
    history_turns=_int_env("OLLAMA_HISTORY_TURNS", DEFAULT_HISTORY_TURNS),
)


@app.post("/conversations")
def start_conversation() -> dict:
    """Start a conversation and return its id plus the URL to post the first turn to."""
    conv = store.create()
    cid = conv.conversation_id
    return {
        "conversationId": cid,
        "links": {"postNext": f"/conversations/{cid}/interactions"},
    }


@app.post("/conversations/{cid}/interactions")
async def send_interaction(
    cid: str,
    request: Request,
    x_interaction_id: str | None = Header(default=None),
) -> dict:
    """Run one chat turn and return the envelope of rendered bubbles.

    Appends the user bubble and the responder's reply (a Markdown text bubble or
    an embedded Adaptive Card fragment). Idempotent by ``X-Interaction-Id``:
    reposting the same id returns the stored envelope without re-running the
    responder.
    """
    if not x_interaction_id:
        raise HTTPException(status_code=400, detail="X-Interaction-Id header required")
    if store.get(cid) is None:
        raise HTTPException(status_code=404, detail="unknown conversation")

    # Idempotent replay: same interaction id returns the stored envelope.
    existing = store.get_interaction(cid, x_interaction_id)
    if existing is not None:
        return envelope(cid, x_interaction_id, existing.messages)

    body = await request.json()
    message = (body.get("data") or {}).get("message")
    if not message:
        raise HTTPException(status_code=400, detail="data.message required")

    conversation = store.get(cid)
    history: list[tuple[str, str]] = []
    for prior_iid in conversation.order:
        prior = conversation.interactions[prior_iid]
        history.append(("user", prior.text))
        history.append(("assistant", prior.reply_text))

    reply = responder.reply(message, history)
    assistant_card = (
        assistant_card_bubble(reply.card_body)
        if reply.card_body is not None
        else assistant_bubble(reply.text)
    )
    messages = [
        Message(role="user", card=user_bubble(message)),
        Message(role="assistant", card=assistant_card),
    ]
    store.add_interaction(
        cid,
        Interaction(
            interaction_id=x_interaction_id,
            text=message,
            messages=messages,
            reply_text=reply.text,
        ),
    )
    return envelope(cid, x_interaction_id, messages)


@app.get("/conversations/{cid}/interactions/{iid}")
def replay_interaction(cid: str, iid: str) -> dict:
    """Return the stored envelope for a past interaction (idempotent replay)."""
    if store.get(cid) is None:
        raise HTTPException(status_code=404, detail="unknown conversation")
    interaction = store.get_interaction(cid, iid)
    if interaction is None:
        raise HTTPException(status_code=404, detail="unknown interaction")
    return envelope(cid, iid, interaction.messages)
