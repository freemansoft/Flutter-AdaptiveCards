import 'package:adaptive_chat_server_dart/src/responder.dart';
import 'package:adaptive_chat_server_dart/src/stats.dart';
import 'package:adaptive_chat_server_dart/src/status.dart';
import 'package:adaptive_chat_server_dart/src/store.dart';
import 'package:test/test.dart';

// Unit tests for buildStatus (the GET /status payload assembler) and
// conversationRef, the hash it substitutes for the raw conversationId. Two
// things would go wrong silently without this file: a responder whose
// describe() throws (a buggy or future custom Responder — describe() is
// arbitrary host code) turning the unauthenticated, wide-open-CORS /status
// endpoint into a 500; and conversationRef losing its non-reversible
// property, which would let any page an operator visits recover a live
// conversationId — the actual bearer credential for reading a transcript —
// from a status poll.

class _StubResponder implements Responder {
  _StubResponder(this._describeImpl);
  final Map<String, dynamic> Function() _describeImpl;

  @override
  Future<Reply> reply(String text, List<(String, String)> history) async =>
      const Reply(text: 'unused');

  @override
  Map<String, dynamic> describe() => _describeImpl();

  @override
  Future<ResponderReadiness> checkReadiness() async =>
      const ResponderReadiness.ready('test double');
}

void main() {
  test('empty store reports zero conversations', () {
    final result = buildStatus(ConversationStore(), EchoResponder());
    expect(result['conversationCount'], 0);
    expect(result['conversations'], isEmpty);
    expect(result['responder'], {'kind': 'echo'});
  });

  // A Responder's describe() is arbitrary code (host-supplied in principle);
  // this pins the fallback that keeps a throwing implementation from
  // turning an unauthenticated GET into a 500 instead of a degraded row.
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

  // order is empty right after store.create(), before any interaction is
  // added — lastInteraction must read null here rather than index into an
  // empty list.
  test('conversation with no interactions reports lastInteraction: null', () {
    final store = ConversationStore()..create();
    final result = buildStatus(store, EchoResponder());
    final row =
        (result['conversations'] as List).single as Map<String, dynamic>;
    expect(row['interactionCount'], 0);
    expect(row['lastInteraction'], isNull);
  });

  // stats is null on any interaction the echo responder handled, or any
  // failed Ollama turn (see InteractionStats' doc comment); totals must
  // skip those without either under-counting or crashing on the null.
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

  // Pins the properties conversationRef's security purpose depends on (see
  // status.dart's doc comment): deterministic across repeated calls so a
  // client can correlate it across polls, distinct per input, and not just
  // a truncated echo of the raw id it stands in for.
  test('conversationRef is a stable 12-char, non-reversible label', () {
    final refA = conversationRef('c_abc123');
    final refB = conversationRef('c_abc123');
    final refC = conversationRef('c_different');
    expect(refA, refB);
    expect(refA, isNot(refC));
    expect(refA, hasLength(12));
    expect(refA, isNot(contains('c_abc123')));
  });

  // ConversationStore backs this with a plain Map; this pins that the
  // reliance on Map's (LinkedHashMap) insertion-order iteration for a
  // stable operator-facing listing is deliberate, not an accident that a
  // future refactor to a different Map type could silently break.
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
