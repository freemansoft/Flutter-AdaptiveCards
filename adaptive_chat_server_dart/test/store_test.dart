import 'package:adaptive_chat_server_dart/src/stats.dart';
import 'package:adaptive_chat_server_dart/src/store.dart';
import 'package:test/test.dart';

// ConversationStore is the server's only record of a conversation between
// requests — process-lifetime, in-memory, keyed entirely by the ids this
// file pins. Losing an invariant here (a minted id colliding, an id lookup
// returning the wrong conversation, insertion order not surviving into
// listConversations) would surface as one client's history bleeding into
// another's, or a status view miscounting turns — not as a loud failure.
void main() {
  group('ConversationStore', () {
    // The c_ prefix is how a caller (or a log line) tells a conversation id
    // apart from an interaction id (i_...) without knowing which store it
    // came from.
    test('create returns c_ prefixed id, discoverable via get', () {
      final store = ConversationStore();
      final conv = store.create();
      expect(conv.conversationId, startsWith('c_'));
      expect(store.get(conv.conversationId), same(conv));
    });

    // Ids are minted from random bytes (_newConversationId); a collision
    // would silently merge two unrelated conversations under one entry.
    test('create returns distinct ids across calls', () {
      final store = ConversationStore();
      final a = store.create();
      final b = store.create();
      expect(a.conversationId, isNot(b.conversationId));
    });

    // A client that skips these fields must still get consistent bubble
    // labels rendered, not nulls flowing through into the UI.
    test('create defaults userLabel/assistantLabel to "user"/"assistant" '
        'and language to null', () {
      final conv = ConversationStore().create();
      expect(conv.userLabel, 'user');
      expect(conv.assistantLabel, 'assistant');
      expect(conv.language, isNull);
    });

    // Confirms the defaults above are actually overridable and not baked
    // into Conversation's constructor.
    test('create stores caller-supplied userLabel/assistantLabel/language', () {
      final conv = ConversationStore().create(
        userLabel: 'Me',
        assistantLabel: 'Bot',
        language: 'es',
      );
      expect(conv.userLabel, 'Me');
      expect(conv.assistantLabel, 'Bot');
      expect(conv.language, 'es');
    });

    // Backs the store's re-adoption path (see ConversationStore.create's doc
    // comment): a client that already believes it owns an id must land on
    // that same conversation, not a freshly minted one.
    test('create uses a caller-supplied conversationId instead of minting '
        'one, discoverable via get', () {
      final store = ConversationStore();
      final conv = store.create(conversationId: 'c_restored');
      expect(conv.conversationId, 'c_restored');
      expect(store.get('c_restored'), same(conv));
    });

    // Callers use this to decide a 404, so it must return null rather than
    // throw.
    test('get returns null for an unknown id', () {
      final store = ConversationStore();
      expect(store.get('missing'), isNull);
    });

    // order is what rebuilds a conversation's history for replay; an
    // interaction that round-trips its content but not its position in
    // order would replay out of sequence.
    test('addInteraction then getInteraction round-trips including stats', () {
      final store = ConversationStore();
      final conv = store.create();
      const stats = InteractionStats(
        promptTokens: 1,
        replyTokens: 2,
        totalMs: 3,
        loadMs: 0,
        promptEvalMs: 1,
        evalMs: 2,
      );
      const interaction = Interaction(
        interactionId: 'i_0001',
        text: 'hi',
        messages: [],
        replyText: 'hello',
        stats: stats,
      );
      store.addInteraction(conv.conversationId, interaction);

      final fetched = store.getInteraction(conv.conversationId, 'i_0001');
      expect(fetched, isNotNull);
      expect(fetched!.text, 'hi');
      expect(fetched.replyText, 'hello');
      expect(fetched.stats, same(stats));
      expect(conv.order, ['i_0001']);
    });

    // null stats specifically means "no measurable token cost" (echo mode
    // or an Ollama failure), distinct from zero; a caller that can't handle
    // null as a valid state would break on every echo-mode turn.
    test('an Interaction round-trips with stats: null (echo mode)', () {
      final store = ConversationStore();
      final conv = store.create();
      store.addInteraction(
        conv.conversationId,
        const Interaction(
          interactionId: 'i_0001',
          text: 'hi',
          messages: [],
          replyText: 'Did you just say: hi',
        ),
      );
      expect(
        store.getInteraction(conv.conversationId, 'i_0001')!.stats,
        isNull,
      );
    });

    // Both misses degrade the same way — null, not a thrown key error — so
    // a caller doesn't need separate code paths for "wrong conversation"
    // versus "wrong interaction".
    test('getInteraction is null for an unknown conversation or '
        'interaction', () {
      final store = ConversationStore();
      expect(store.getInteraction('missing', 'i_0001'), isNull);
      final conv = store.create();
      expect(store.getInteraction(conv.conversationId, 'i_0001'), isNull);
    });

    // A conversation list rendered out of order would look like the server
    // reordered someone's sessions.
    test('listConversations preserves creation order', () {
      final store = ConversationStore();
      final a = store.create();
      final b = store.create();
      final c = store.create();
      expect(
        store.listConversations().map((conv) => conv.conversationId).toList(),
        [a.conversationId, b.conversationId, c.conversationId],
      );
    });

    // The base case an iteration-based caller (e.g. a status endpoint) must
    // handle before any conversation exists.
    test('listConversations is empty for a fresh store', () {
      expect(ConversationStore().listConversations(), isEmpty);
    });
  });
}
