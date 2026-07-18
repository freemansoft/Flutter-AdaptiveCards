from app.cards import assistant_bubble, envelope, user_bubble
from app.store import Message


def _first_columnset(card: dict) -> dict:
    return card["body"][0]


def test_user_bubble_is_right_aligned_accent():
    card = user_bubble("hello")
    cols = _first_columnset(card)["columns"]
    # spacer first, content second -> pushes bubble right
    assert cols[0]["width"] == "stretch"
    assert cols[1]["width"] == "auto"
    container = cols[1]["items"][0]
    assert container["style"] == "accent"
    assert container["items"][0]["text"] == "hello"


def test_assistant_bubble_is_left_aligned_emphasis():
    card = assistant_bubble("Did you just say: hi")
    cols = _first_columnset(card)["columns"]
    assert cols[0]["width"] == "auto"
    assert cols[1]["width"] == "stretch"
    container = cols[0]["items"][0]
    assert container["style"] == "emphasis"
    assert container["items"][0]["text"] == "Did you just say: hi"


def test_envelope_shape():
    msgs = [
        Message(role="user", card=user_bubble("hi")),
        Message(role="assistant", card=assistant_bubble("Did you just say: hi")),
    ]
    env = envelope("c_1", "i_0001", msgs)
    assert env["conversationId"] == "c_1"
    assert env["interactionId"] == "i_0001"
    assert len(env["messages"]) == 2
    assert env["messages"][0] == msgs[0].card
    assert env["links"]["self"] == "/conversations/c_1/interactions/i_0001"
    assert env["links"]["postNext"] == "/conversations/c_1/interactions"
