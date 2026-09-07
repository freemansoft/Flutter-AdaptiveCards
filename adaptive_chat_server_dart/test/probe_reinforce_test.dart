import 'package:test/test.dart';

// Relative: probe_support lives outside lib/.
import '../tool/model_probes/probe_support.dart';

// Not a test of server/app behavior: buildProbeMessages is measurement-tool
// plumbing shared by the model_probes scripts, not anything the running
// server calls. It exists so an experimental "reminder" message (candidate
// N1 — a second system message re-stating the card instructions right
// before generation) can be tested for its ordering without an HTTP round
// trip to a live Ollama. The reminder's entire hypothesis is proximity to
// generation, so if it drifted to the wrong position relative to history and
// the current turn, a probe run would be measuring a different candidate
// than the one it claims to, silently. See buildProbeMessages's own doc
// comment: this file is the place that assertion is pinned rather than left
// to inspection.
void main() {
  group('buildProbeMessages', () {
    // The baseline the reminder-position tests below are contrasting
    // against: with no reminder given, the shape must match plain
    // OllamaResponder wiring exactly, or the "reminder inserted" tests
    // wouldn't be isolating the reminder's effect.
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

    // Guards against an implementation that only inserts the reminder
    // relative to a history entry (e.g. "after the last history item") and
    // silently drops it when history is empty, which the non-empty-history
    // test above wouldn't catch.
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

    // Pins the role-assignment rule itself (even index -> user, odd ->
    // assistant) independent of the reminder — a probe's `--history` flag
    // takes plain strings with no role tag, so this convention is the only
    // thing keeping alternating turns from being sent with swapped roles.
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
