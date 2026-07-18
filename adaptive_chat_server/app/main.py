"""FastAPI entrypoint for the Adaptive Chat echo backend."""
from __future__ import annotations

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.responder import EchoResponder
from app.store import ConversationStore

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
