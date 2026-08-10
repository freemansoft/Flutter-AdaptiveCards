import 'package:adaptive_chat_server_dart/src/stats.dart';
import 'package:adaptive_chat_server_dart/src/store.dart';
import 'package:test/test.dart';

void main() {
  group('ConversationStore', () {
    test(
      'create returns c_ prefixed id, discoverable via get',
      () {
        final store = ConversationStore();
        final conv = store.create();
        expect(conv.conversationId, startsWith('c_'));
        expect(store.get(conv.conversationId), same(conv));
      },
    );

    test('create returns distinct ids across calls', () {
      final store = ConversationStore();
      final a = store.create();
      final b = store.create();
      expect(a.conversationId, isNot(b.conversationId));
    });

    test('get returns null for an unknown id', () {
      final store = ConversationStore();
      expect(store.get('missing'), isNull);
    });

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

    test(
      'hasInteraction is false for an unknown conversation or interaction',
      () {
        final store = ConversationStore();
        expect(store.hasInteraction('missing', 'i_0001'), isFalse);
        final conv = store.create();
        expect(store.hasInteraction(conv.conversationId, 'i_0001'), isFalse);
      },
    );

    test('hasInteraction is true once the interaction is added', () {
      final store = ConversationStore();
      final conv = store.create();
      store.addInteraction(
        conv.conversationId,
        const Interaction(interactionId: 'i_0001', text: 'hi', messages: []),
      );
      expect(store.hasInteraction(conv.conversationId, 'i_0001'), isTrue);
    });

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

    test('listConversations is empty for a fresh store', () {
      expect(ConversationStore().listConversations(), isEmpty);
    });
  });
}
