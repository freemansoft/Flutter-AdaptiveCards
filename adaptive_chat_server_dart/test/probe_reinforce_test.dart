import 'package:test/test.dart';

// Relative: probe_support lives outside lib/.
import '../tool/model_probes/probe_support.dart';

void main() {
  group('buildProbeMessages', () {
    test('without a reminder: system, history, user', () {
      final messages = buildProbeMessages(
        systemPrompt: 'SYS',
        userPrompt: 'NOW',
        history: const ['u1', 'a1'],
      );
      expect(
        messages.map((m) => '${m['role']}:${m['content']}').toList(),
        equals(['system:SYS', 'user:u1', 'assistant:a1', 'user:NOW']),
      );
    });

    test('with a reminder: it lands AFTER history, BEFORE the user turn', () {
      // The whole point of N1 is adjacency to generation. If the reminder
      // drifts before the history, this candidate is not being tested.
      final messages = buildProbeMessages(
        systemPrompt: 'SYS',
        userPrompt: 'NOW',
        history: const ['u1', 'a1'],
        reminder: 'REMIND',
      );
      expect(
        messages.map((m) => '${m['role']}:${m['content']}').toList(),
        equals([
          'system:SYS',
          'user:u1',
          'assistant:a1',
          'system:REMIND',
          'user:NOW',
        ]),
      );
    });

    test('a reminder with empty history still precedes the user turn', () {
      final messages = buildProbeMessages(
        systemPrompt: 'SYS',
        userPrompt: 'NOW',
        reminder: 'REMIND',
      );
      expect(
        messages.map((m) => '${m['role']}:${m['content']}').toList(),
        equals(['system:SYS', 'system:REMIND', 'user:NOW']),
      );
    });

    test('history alternates user/assistant from index 0', () {
      final messages = buildProbeMessages(
        systemPrompt: 'SYS',
        userPrompt: 'NOW',
        history: const ['a', 'b', 'c'],
      );
      expect(
        messages.map((m) => m['role']).toList(),
        equals(['system', 'user', 'assistant', 'user', 'user']),
      );
    });
  });
}
