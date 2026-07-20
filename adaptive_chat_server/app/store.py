"""In-memory conversation state for the Adaptive Chat demo."""
from __future__ import annotations

import uuid
from dataclasses import dataclass, field


@dataclass
class Message:
    """One rendered bubble: an author role plus its Adaptive Card map."""

    role: str
    card: dict


@dataclass
class Interaction:
    """One send/response cycle within a conversation."""

    interaction_id: str
    text: str
    messages: list[Message]
    reply_text: str = ""


@dataclass
class Conversation:
    """A session: ordered interactions keyed by client-supplied id."""

    conversation_id: str
    interactions: dict[str, Interaction] = field(default_factory=dict)
    order: list[str] = field(default_factory=list)


class ConversationStore:
    """Process-lifetime store of conversations (lost on restart)."""

    def __init__(self) -> None:
        self._conversations: dict[str, Conversation] = {}

    def create(self) -> Conversation:
        cid = f"c_{uuid.uuid4().hex[:12]}"
        conv = Conversation(conversation_id=cid)
        self._conversations[cid] = conv
        return conv

    def get(self, cid: str) -> Conversation | None:
        return self._conversations.get(cid)

    def has_interaction(self, cid: str, iid: str) -> bool:
        conv = self._conversations.get(cid)
        return bool(conv and iid in conv.interactions)

    def add_interaction(self, cid: str, interaction: Interaction) -> None:
        conv = self._conversations[cid]
        conv.interactions[interaction.interaction_id] = interaction
        conv.order.append(interaction.interaction_id)

    def get_interaction(self, cid: str, iid: str) -> Interaction | None:
        conv = self._conversations.get(cid)
        if conv is None:
            return None
        return conv.interactions.get(iid)
