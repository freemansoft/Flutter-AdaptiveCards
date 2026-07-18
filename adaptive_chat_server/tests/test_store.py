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
