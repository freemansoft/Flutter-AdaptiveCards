from fastapi.testclient import TestClient

from app.main import app
from app.responder import Reply

client = TestClient(app)


class _CardStubResponder:
    def reply(self, text, history):
        return Reply(
            text='{"type":"AdaptiveCard"}',
            card_body=[{"type": "Input.Date", "id": "when"}],
        )


def test_start_conversation_returns_id_and_post_next():
    resp = client.post("/conversations")
    assert resp.status_code == 200
    body = resp.json()
    cid = body["conversationId"]
    assert cid.startswith("c_")
    assert body["links"]["postNext"] == f"/conversations/{cid}/interactions"


def _start() -> str:
    return client.post("/conversations").json()["conversationId"]


def _send(cid: str, iid: str, message: str):
    return client.post(
        f"/conversations/{cid}/interactions",
        headers={"X-Interaction-Id": iid},
        json={"kind": "submit", "actionId": "send", "data": {"message": message}},
    )


def test_send_returns_two_bubbles_and_links():
    cid = _start()
    resp = _send(cid, "i_0001", "hi there")
    assert resp.status_code == 200
    body = resp.json()
    assert body["interactionId"] == "i_0001"
    assert len(body["messages"]) == 2
    user_text = body["messages"][0]["body"][0]["columns"][1]["items"][0]["items"][0]["text"]
    reply_text = body["messages"][1]["body"][0]["columns"][0]["items"][0]["items"][0]["text"]
    assert user_text == "hi there"
    assert reply_text == "Did you just say: hi there"
    assert body["links"]["postNext"] == f"/conversations/{cid}/interactions"


def test_send_second_turn_still_echoes_correctly():
    # EchoResponder ignores history, so building it in the send route must
    # not change the reply for either turn.
    cid = _start()
    first = _send(cid, "i_0001", "first message").json()
    second = _send(cid, "i_0002", "second message").json()

    first_reply = first["messages"][1]["body"][0]["columns"][0]["items"][0]["items"][0]["text"]
    second_reply = second["messages"][1]["body"][0]["columns"][0]["items"][0]["items"][0][
        "text"
    ]
    assert first_reply == "Did you just say: first message"
    assert second_reply == "Did you just say: second message"


def test_send_renders_card_reply_in_assistant_bubble(monkeypatch):
    monkeypatch.setattr("app.main.responder", _CardStubResponder())
    cid = _start()
    resp = _send(cid, "i_card1", "book me")
    assert resp.status_code == 200
    body = resp.json()
    container = body["messages"][1]["body"][0]["columns"][0]["items"][0]
    assert container["style"] == "emphasis"
    assert container["items"] == [{"type": "Input.Date", "id": "when"}]


def test_send_is_idempotent_by_interaction_id():
    cid = _start()
    first = _send(cid, "i_0007", "same").json()
    second = _send(cid, "i_0007", "IGNORED second body").json()
    # Stored envelope is returned unchanged; the second message is not reprocessed.
    assert second == first


def test_send_missing_header_is_400():
    cid = _start()
    resp = client.post(
        f"/conversations/{cid}/interactions",
        json={"kind": "submit", "data": {"message": "hi"}},
    )
    assert resp.status_code == 400


def test_send_missing_message_is_400():
    cid = _start()
    resp = client.post(
        f"/conversations/{cid}/interactions",
        headers={"X-Interaction-Id": "i_0001"},
        json={"kind": "submit", "data": {}},
    )
    assert resp.status_code == 400


def test_send_unknown_conversation_is_404():
    resp = _send("c_missing", "i_0001", "hi")
    assert resp.status_code == 404


def test_replay_returns_stored_envelope():
    cid = _start()
    sent = _send(cid, "i_0009", "replay me").json()
    resp = client.get(f"/conversations/{cid}/interactions/i_0009")
    assert resp.status_code == 200
    assert resp.json() == sent


def test_replay_unknown_interaction_is_404():
    cid = _start()
    resp = client.get(f"/conversations/{cid}/interactions/i_missing")
    assert resp.status_code == 404
