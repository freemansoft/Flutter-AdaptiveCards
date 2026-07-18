"""FastAPI entrypoint for the Adaptive Chat echo backend."""
from __future__ import annotations

from fastapi import FastAPI, Header, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware

from app.cards import assistant_bubble, envelope, user_bubble
from app.responder import EchoResponder
from app.store import ConversationStore, Interaction, Message

app = FastAPI(title="Adaptive Chat Server")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

store = ConversationStore()
responder = EchoResponder()


@app.post("/conversations")
def start_conversation() -> dict:
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

    reply_text = responder.reply(message)
    messages = [
        Message(role="user", card=user_bubble(message)),
        Message(role="assistant", card=assistant_bubble(reply_text)),
    ]
    store.add_interaction(
        cid,
        Interaction(interaction_id=x_interaction_id, text=message, messages=messages),
    )
    return envelope(cid, x_interaction_id, messages)


@app.get("/conversations/{cid}/interactions/{iid}")
def replay_interaction(cid: str, iid: str) -> dict:
    if store.get(cid) is None:
        raise HTTPException(status_code=404, detail="unknown conversation")
    interaction = store.get_interaction(cid, iid)
    if interaction is None:
        raise HTTPException(status_code=404, detail="unknown interaction")
    return envelope(cid, iid, interaction.messages)
