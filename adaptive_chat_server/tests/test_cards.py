from app.cards import (
    _BUBBLE_WEIGHT,
    _SPACER_WEIGHT,
    assistant_bubble,
    assistant_card_bubble,
    envelope,
    user_bubble,
)
from app.store import Message


def _first_columnset(card: dict) -> dict:
    return card["body"][0]


def test_user_bubble_is_right_aligned_accent():
    card = user_bubble("hello")
    cols = _first_columnset(card)["columns"]
    # spacer (25%) first, content (75%) second -> bubble spans the right 75%
    assert cols[0]["width"] == _SPACER_WEIGHT
    assert cols[1]["width"] == _BUBBLE_WEIGHT
    container = cols[1]["items"][0]
    assert container["style"] == "accent"
    assert container["roundedCorners"] is True
    assert container["items"][0]["text"] == "hello"


def test_assistant_bubble_is_left_aligned_emphasis():
    card = assistant_bubble("Did you just say: hi")
    cols = _first_columnset(card)["columns"]
    # content (75%) first, spacer (25%) second -> bubble spans the left 75%
    assert cols[0]["width"] == _BUBBLE_WEIGHT
    assert cols[1]["width"] == _SPACER_WEIGHT
    container = cols[0]["items"][0]
    assert container["style"] == "emphasis"
    assert container["roundedCorners"] is True
    assert container["items"][0]["text"] == "Did you just say: hi"


def test_bubble_spans_seventy_five_percent():
    # 3:1 weighting => the content column is 75% of the row.
    assert _BUBBLE_WEIGHT / (_BUBBLE_WEIGHT + _SPACER_WEIGHT) == 0.75


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


def test_assistant_card_bubble_embeds_fragment_in_left_emphasis_container():
    fragment = [
        {"type": "TextBlock", "text": "Pick a date"},
        {"type": "Input.Date", "id": "when"},
    ]
    card = assistant_card_bubble(fragment)
    cols = _first_columnset(card)["columns"]
    # content (75%) first, spacer (25%) second -> left-aligned like a text reply
    assert cols[0]["width"] == _BUBBLE_WEIGHT
    assert cols[1]["width"] == _SPACER_WEIGHT
    container = cols[0]["items"][0]
    assert container["style"] == "emphasis"
    assert container["roundedCorners"] is True
    # the model's fragment is the container's items verbatim
    assert container["items"] == fragment
