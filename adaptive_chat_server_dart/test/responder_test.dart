import 'package:adaptive_chat_server_dart/src/responder.dart';
import 'package:test/test.dart';

// EchoResponder is the server's `--echo` demo mode (bin/server.dart runs it
// whenever --echo is passed instead of --ollama-url), specifically so the
// chat pipeline — routing, conversation storage, the client — can be
// exercised with zero external dependencies: no Ollama, no model, no
// network. These tests pin the one behavior that mode promises: a fixed,
// history-blind, card-free echo. If any of that drifted (e.g. it started
// reading history, or ever produced a card), the demo would stop being a
// safe zero-dependency baseline for exercising everything else.
void main() {
  group('EchoResponder', () {
    test('echoes the text back with the fixed prefix', () async {
      final reply = await EchoResponder().reply('hello', const []);
      expect(reply.text, 'Did you just say: hello');
    });

    // EchoResponder.reply's signature accepts history, but the implementation
    // never reads it — this confirms that's a real contract, not just an
    // untested parameter that happens to be unused today.
    test('ignores history entirely', () async {
      final history = [('user', 'earlier'), ('assistant', 'earlier reply')];
      final reply = await EchoResponder().reply('now', history);
      expect(reply.text, 'Did you just say: now');
    });

    // A widgetbook/client renders cardBody specially — the demo mode must
    // never accidentally trigger that path, since its whole point is to be a
    // plain-text baseline.
    test('never returns a card body', () async {
      final reply = await EchoResponder().reply('hello', const []);
      expect(reply.cardBody, isNull);
    });

    // stats backs GET /status token/timing reporting; echo mode calls no
    // model, so there's nothing real to report and it must not fabricate a
    // zeroed InteractionStats that would look like a measured cost.
    test('never returns stats', () async {
      final reply = await EchoResponder().reply('hello', const []);
      expect(reply.stats, isNull);
    });

    // describe() is served verbatim as GET /status — 'kind: echo' is how an
    // operator (or the client) distinguishes the demo mode from a real
    // Ollama-backed responder without guessing from behavior.
    test('describe reports kind: echo', () {
      expect(EchoResponder().describe(), {'kind': 'echo'});
    });
  });
}
