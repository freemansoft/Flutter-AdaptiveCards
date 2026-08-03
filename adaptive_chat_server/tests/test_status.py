import json

from app.responder import EchoResponder
from app.stats import InteractionStats
from app.status import build_status, conversation_ref
from app.store import ConversationStore, Interaction, Message


def _stats(prompt: int, reply: int) -> InteractionStats:
    return InteractionStats(
        prompt_tokens=prompt,
        reply_tokens=reply,
        total_ms=100,
        load_ms=1,
        prompt_eval_ms=20,
        eval_ms=70,
    )


def _add(store, cid, iid, stats=None):
    store.add_interaction(
        cid, Interaction(interaction_id=iid, text="hi", messages=[], stats=stats)
    )


def test_empty_store_reports_no_conversations():
    body = build_status(ConversationStore(), EchoResponder())
    assert body["conversationCount"] == 0
    assert body["conversations"] == []
    assert body["responder"] == {"kind": "echo"}


def test_totals_sum_only_interactions_with_stats():
    store = ConversationStore()
    cid = store.create().conversation_id
    _add(store, cid, "i_0001", _stats(100, 20))
    _add(store, cid, "i_0002", None)
    _add(store, cid, "i_0003", _stats(200, 30))
    row = build_status(store, EchoResponder())["conversations"][0]
    assert row["interactionCount"] == 3
    assert row["totals"] == {
        "promptTokens": 300,
        "replyTokens": 50,
        "totalTokens": 350,
    }


def test_last_interaction_is_the_most_recent():
    store = ConversationStore()
    cid = store.create().conversation_id
    _add(store, cid, "i_0001", _stats(100, 20))
    _add(store, cid, "i_0002", _stats(200, 30))
    last = build_status(store, EchoResponder())["conversations"][0]["lastInteraction"]
    assert last["stats"]["promptTokens"] == 200
    assert last["stats"]["totalTokens"] == 230


def test_last_interaction_stats_null_when_absent():
    store = ConversationStore()
    cid = store.create().conversation_id
    _add(store, cid, "i_0001", None)
    last = build_status(store, EchoResponder())["conversations"][0]["lastInteraction"]
    assert last["stats"] is None


def test_conversation_with_no_interactions_has_null_last():
    store = ConversationStore()
    store.create()
    row = build_status(store, EchoResponder())["conversations"][0]
    assert row["interactionCount"] == 0
    assert row["lastInteraction"] is None
    assert row["totals"]["totalTokens"] == 0


def test_conversations_appear_in_creation_order():
    store = ConversationStore()
    first = store.create().conversation_id
    second = store.create().conversation_id
    body = build_status(store, EchoResponder())
    assert [c["conversationRef"] for c in body["conversations"]] == [
        conversation_ref(first),
        conversation_ref(second),
    ]
    assert body["conversationCount"] == 2


def test_responder_without_describe_reports_unknown():
    class _Stub:
        def reply(self, text, history):
            raise AssertionError("reply should not be called by build_status")

    body = build_status(ConversationStore(), _Stub())
    assert body["responder"] == {"kind": "unknown"}


def test_status_carries_no_message_text():
    store = ConversationStore()
    cid = store.create().conversation_id
    store.add_interaction(
        cid,
        Interaction(
            interaction_id="i_0001",
            text="my secret question",
            messages=[Message(role="user", card={"type": "AdaptiveCard"})],
            reply_text="my secret answer",
        ),
    )
    serialized = json.dumps(build_status(store, EchoResponder()))
    assert "my secret question" not in serialized
    assert "my secret answer" not in serialized


def test_status_carries_no_raw_conversation_id():
    # The raw conversation id is the bearer credential for the transcript
    # endpoints (GET/POST .../interactions); /status is unauthenticated with
    # CORS wide open, so only the non-reversible ref may appear here.
    store = ConversationStore()
    cid = store.create().conversation_id
    serialized = json.dumps(build_status(store, EchoResponder()))
    assert cid not in serialized
    assert conversation_ref(cid) in serialized
