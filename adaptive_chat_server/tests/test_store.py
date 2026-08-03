from app.stats import InteractionStats
from app.store import ConversationStore, Interaction, Message


def test_create_returns_unique_conversation_ids():
    store = ConversationStore()
    a = store.create()
    b = store.create()
    assert a.conversation_id != b.conversation_id
    assert store.get(a.conversation_id) is a


def test_add_and_get_interaction():
    store = ConversationStore()
    conv = store.create()
    inter = Interaction(
        interaction_id="i_0001",
        text="hi",
        messages=[Message(role="user", card={"type": "AdaptiveCard"})],
    )
    assert store.has_interaction(conv.conversation_id, "i_0001") is False
    store.add_interaction(conv.conversation_id, inter)
    assert store.has_interaction(conv.conversation_id, "i_0001") is True
    assert store.get_interaction(conv.conversation_id, "i_0001") is inter


def test_get_missing_conversation_returns_none():
    store = ConversationStore()
    assert store.get("nope") is None
    assert store.get_interaction("nope", "i_0001") is None


def test_interaction_stats_default_to_none():
    inter = Interaction(interaction_id="i_0001", text="hi", messages=[])
    assert inter.stats is None


def test_interaction_round_trips_stats():
    store = ConversationStore()
    conv = store.create()
    stats = InteractionStats(
        prompt_tokens=10,
        reply_tokens=5,
        total_ms=100,
        load_ms=1,
        prompt_eval_ms=20,
        eval_ms=70,
    )
    store.add_interaction(
        conv.conversation_id,
        Interaction(interaction_id="i_0001", text="hi", messages=[], stats=stats),
    )
    stored = store.get_interaction(conv.conversation_id, "i_0001")
    assert stored.stats is stats


def test_list_conversations_returns_creation_order():
    store = ConversationStore()
    first = store.create()
    second = store.create()
    assert [c.conversation_id for c in store.list_conversations()] == [
        first.conversation_id,
        second.conversation_id,
    ]


def test_list_conversations_empty_store():
    assert ConversationStore().list_conversations() == []
