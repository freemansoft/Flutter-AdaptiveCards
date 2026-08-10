import 'package:adaptive_chat_server_dart/src/responder.dart';
import 'package:test/test.dart';

void main() {
  group('EchoResponder', () {
    test('echoes the text back with the fixed prefix', () async {
      final reply = await EchoResponder().reply('hello', const []);
      expect(reply.text, 'Did you just say: hello');
    });

    test('ignores history entirely', () async {
      final history = [('user', 'earlier'), ('assistant', 'earlier reply')];
      final reply = await EchoResponder().reply('now', history);
      expect(reply.text, 'Did you just say: now');
    });

    test('never returns a card body', () async {
      final reply = await EchoResponder().reply('hello', const []);
      expect(reply.cardBody, isNull);
    });

    test('never returns stats', () async {
      final reply = await EchoResponder().reply('hello', const []);
      expect(reply.stats, isNull);
    });

    test('describe reports kind: echo', () {
      expect(EchoResponder().describe(), {'kind': 'echo'});
    });
  });
}
