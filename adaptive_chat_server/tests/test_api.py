from fastapi.testclient import TestClient

from app.main import app
from app.responder import Reply
from app.stats import InteractionStats
from app.status import conversation_ref

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
    user_text = body["messages"][0]["body"][1]["columns"][1]["items"][0]["items"][0]["text"]
    reply_text = body["messages"][1]["body"][1]["columns"][0]["items"][0]["items"][0]["text"]
    assert user_text == "hi there"
    assert reply_text == "Did you just say: hi there"
    assert body["links"]["postNext"] == f"/conversations/{cid}/interactions"


def test_send_second_turn_still_echoes_correctly():
    # EchoResponder ignores history, so building it in the send route must
    # not change the reply for either turn.
    cid = _start()
    first = _send(cid, "i_0001", "first message").json()
    second = _send(cid, "i_0002", "second message").json()

    first_reply = first["messages"][1]["body"][1]["columns"][0]["items"][0]["items"][0]["text"]
    second_reply = second["messages"][1]["body"][1]["columns"][0]["items"][0]["items"][0][
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
    # Card replies render full-width (no ColumnSet) so a nested Carousel lays out.
    assert body["messages"][1]["body"][0]["type"] == "TextBlock"
    container = body["messages"][1]["body"][1]
    assert container["type"] == "Container"
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


class _StatsStubResponder:
    def reply(self, text, history):
        return Reply(
            text="ok",
            stats=InteractionStats(
                prompt_tokens=1500,
                reply_tokens=300,
                total_ms=8200,
                load_ms=12,
                prompt_eval_ms=900,
                eval_ms=7200,
            ),
        )

    def describe(self):
        return {"kind": "stub"}


def _rows_by_ref() -> dict:
    return {
        c["conversationRef"]: c for c in client.get("/status").json()["conversations"]
    }


def test_status_reports_conversations_and_echo_responder():
    cid_a = _start()
    _send(cid_a, "i_s001", "hello")
    _send(cid_a, "i_s002", "again")
    cid_b = _start()

    body = client.get("/status").json()
    assert body["responder"]["kind"] == "echo"
    assert body["conversationCount"] >= 2

    rows = {c["conversationRef"]: c for c in body["conversations"]}
    ref_a = conversation_ref(cid_a)
    ref_b = conversation_ref(cid_b)
    assert rows[ref_a]["interactionCount"] == 2
    assert rows[ref_a]["lastInteraction"]["stats"] is None
    assert rows[ref_a]["totals"]["totalTokens"] == 0
    assert rows[ref_b]["interactionCount"] == 0
    assert rows[ref_b]["lastInteraction"] is None


def test_status_replay_does_not_increment_interaction_count():
    cid = _start()
    _send(cid, "i_s010", "hello")
    _send(cid, "i_s010", "hello")
    assert _rows_by_ref()[conversation_ref(cid)]["interactionCount"] == 1


def test_status_reports_stats_captured_from_the_responder(monkeypatch):
    monkeypatch.setattr("app.main.responder", _StatsStubResponder())
    cid = _start()
    _send(cid, "i_s020", "hello")

    body = client.get("/status").json()
    assert body["responder"] == {"kind": "stub"}
    row = {c["conversationRef"]: c for c in body["conversations"]}[conversation_ref(cid)]
    assert row["totals"] == {
        "promptTokens": 1500,
        "replyTokens": 300,
        "totalTokens": 1800,
    }
    assert row["lastInteraction"]["stats"]["tokensPerSecond"] == 41.7
    assert row["lastInteraction"]["stats"]["evalMs"] == 7200


def test_send_envelope_is_unchanged_by_stats():
    cid = _start()
    body = _send(cid, "i_s030", "hello").json()
    assert set(body) == {"conversationId", "interactionId", "messages", "links"}


def test_status_is_rendered_as_indented_json():
    resp = client.get("/status")
    assert resp.status_code == 200
    assert resp.headers["content-type"].startswith("application/json")
    # Indented for a human reading curl output, not FastAPI's compact default.
    assert '\n  "responder"' in resp.text
    assert '\n  "conversations"' in resp.text
    assert resp.text.endswith("\n")
    # Indentation must not stop it being parseable — jq and any client still work.
    assert resp.json()["responder"]["kind"] == "echo"


def test_interaction_envelope_stays_compact():
    # Only /status is indented. The chat routes are machine-consumed by the
    # Flutter client and their wire format must not change.
    cid = _start()
    resp = _send(cid, "i_s040", "hello")
    assert "\n" not in resp.text
