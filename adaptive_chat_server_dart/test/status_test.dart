import 'package:adaptive_chat_server_dart/src/responder.dart';
import 'package:adaptive_chat_server_dart/src/stats.dart';
import 'package:adaptive_chat_server_dart/src/status.dart';
import 'package:adaptive_chat_server_dart/src/store.dart';
import 'package:test/test.dart';

class _StubResponder implements Responder {
  _StubResponder(this._describeImpl);
  final Map<String, dynamic> Function() _describeImpl;

  @override
  Future<Reply> reply(String text, List<(String, String)> history) async =>
      const Reply(text: 'unused');

  @override
  Map<String, dynamic> describe() => _describeImpl();
}

void main() {
  test('empty store reports zero conversations', () {
    final result = buildStatus(ConversationStore(), EchoResponder());
    expect(result['conversationCount'], 0);
    expect(result['conversations'], isEmpty);
    expect(result['responder'], {'kind': 'echo'});
  });

  test(
    'a responder whose describe() throws degrades to unknown',
    () {
      final result = buildStatus(
        ConversationStore(),
        _StubResponder(() => throw StateError('boom')),
      );
      expect(result['responder'], {'kind': 'unknown'});
    },
  );

  test('conversation with no interactions reports lastInteraction: null', () {
    final store = ConversationStore()..create();
    final result = buildStatus(store, EchoResponder());
    final row =
        (result['conversations'] as List).single as Map<String, dynamic>;
    expect(row['interactionCount'], 0);
    expect(row['lastInteraction'], isNull);
  });

  test('totals sum only interactions with non-null stats', () {
    final store = ConversationStore();
    final conv = store.create();
    const stats1 = InteractionStats(
      promptTokens: 10,
      replyTokens: 5,
      totalMs: 0,
      loadMs: 0,
      promptEvalMs: 0,
      evalMs: 0,
    );
    store
      ..addInteraction(
        conv.conversationId,
        const Interaction(
          interactionId: 'i_0001',
          text: 'a',
          messages: [],
          stats: stats1,
        ),
      )
      ..addInteraction(
        conv.conversationId,
        const Interaction(interactionId: 'i_0002', text: 'b', messages: []),
      );
    final result = buildStatus(store, EchoResponder());
    final row =
        (result['conversations'] as List).single as Map<String, dynamic>;
    expect(row['interactionCount'], 2);
    expect(row['totals'], {
      'promptTokens': 10,
      'replyTokens': 5,
      'totalTokens': 15,
    });
    // Last interaction (i_0002) has no stats.
    expect((row['lastInteraction'] as Map)['stats'], isNull);
  });

  test('conversationRef is a stable 12-char, non-reversible label', () {
    final refA = conversationRef('c_abc123');
    final refB = conversationRef('c_abc123');
    final refC = conversationRef('c_different');
    expect(refA, refB);
    expect(refA, isNot(refC));
    expect(refA, hasLength(12));
    expect(refA, isNot(contains('c_abc123')));
  });

  test('conversations appear in creation order', () {
    final store = ConversationStore();
    final a = store.create();
    final b = store.create();
    final result = buildStatus(store, EchoResponder());
    final refs = (result['conversations'] as List)
        .map((row) => (row as Map)['conversationRef'])
        .toList();
    expect(
      refs,
      [conversationRef(a.conversationId), conversationRef(b.conversationId)],
    );
  });
}
