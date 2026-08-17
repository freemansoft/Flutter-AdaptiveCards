import 'package:test/test.dart';

// Relative: both files live outside lib/.
import '../tool/model_probes/probe_support.dart';
import '../tool/model_probes/shape_cases.dart';

/// Builds the outcome a real probe would produce for [reply], using the
/// server's own judgement — so these tests exercise the same path the probe
/// does rather than a hand-built stand-in.
ProbeOutcome outcomeFor(String reply) => judgeReply(reply, 0);

const dateCase = ShapeCase(
  id: 'date',
  prompt: 'Book me a meeting. Ask me for a date.',
  accepted: {'Input.Date'},
  requiresInput: true,
);

const tableCase = ShapeCase(
  id: 'table',
  prompt: 'Table of the 4 largest planets.',
  accepted: {'Table'},
);

const proseCase = ShapeCase(
  id: 'prose',
  prompt: 'In two sentences, why is the sky blue?',
  accepted: {},
);

void main() {
  group('judgeShape', () {
    test('ok when an accepted type is present', () {
      final r = judgeShape(
        dateCase,
        outcomeFor('{"type":"Input.Date","id":"when"}'),
      );
      expect(r.pass, isTrue);
      expect(r.label, 'ok');
      expect(r.found, contains('Input.Date'));
    });

    test('ok when ANY of several accepted types is present', () {
      const facts = ShapeCase(
        id: 'facts',
        prompt: 'Summarize the specs as labelled facts.',
        accepted: {'FactSet', 'Table'},
      );
      final r = judgeShape(
        facts,
        outcomeFor(
          '{"type":"Table","columns":[{"width":1}],"rows":[]}',
        ),
      );
      expect(r.pass, isTrue, reason: 'Table is an accepted alternative');
    });

    test('no-input when a card has content but no Input.* at all', () {
      final r = judgeShape(
        dateCase,
        outcomeFor('{"type":"TextBlock","text":"Sure, when?","wrap":true}'),
      );
      expect(r.pass, isFalse);
      expect(r.label, 'no-input');
    });

    test('wrong-shape when an input is present but the wrong one', () {
      // This is the distinction no-input-before-wrong-shape buys us.
      final r = judgeShape(
        dateCase,
        outcomeFor('{"type":"Input.Text","id":"when"}'),
      );
      expect(r.pass, isFalse);
      expect(r.label, 'wrong-shape');
      expect(r.found, contains('Input.Text'));
    });

    test('wrong-shape for a non-input case with the wrong element', () {
      final r = judgeShape(
        tableCase,
        outcomeFor('{"type":"TextBlock","text":"Jupiter is big","wrap":true}'),
      );
      expect(r.pass, isFalse);
      expect(r.label, 'wrong-shape');
    });

    test('prose when a card was expected and clean prose came back', () {
      final r = judgeShape(tableCase, outcomeFor('Jupiter is the largest.'));
      expect(r.pass, isFalse);
      expect(r.label, 'prose');
      expect(r.found, isEmpty);
    });

    test('broken when the reply is malformed JSON', () {
      final r = judgeShape(
        tableCase,
        outcomeFor('{"type":"Table","rows":[{"type":"TableRow"'),
      );
      expect(r.pass, isFalse);
      expect(r.label, startsWith('broken'));
    });

    test('broken when prose wraps a card', () {
      final r = judgeShape(
        tableCase,
        outcomeFor(
          'Sure, here you go:\n\n```json\n'
          '{"type":"TextBlock","text":"hi","wrap":true}\n```',
        ),
      );
      expect(r.pass, isFalse);
      expect(
        r.label,
        startsWith('broken'),
        reason: 'the user sees raw JSON, so this is not a passing prose reply',
      );
    });

    test('prose-ok when the control case correctly returns prose', () {
      final r = judgeShape(
        proseCase,
        outcomeFor(
          'Sunlight scatters off air molecules, and blue scatters '
          'most. That is why the sky looks blue.',
        ),
      );
      expect(r.pass, isTrue);
      expect(r.label, 'prose-ok');
    });

    test('unwanted-card when the control case returns a card', () {
      final r = judgeShape(
        proseCase,
        outcomeFor('{"type":"TextBlock","text":"Blue scatters","wrap":true}'),
      );
      expect(r.pass, isFalse);
      expect(r.label, 'unwanted-card');
    });

    test('describe() names what was found on a wrong-shape failure', () {
      final r = judgeShape(
        tableCase,
        outcomeFor('{"type":"TextBlock","text":"x","wrap":true}'),
      );
      expect(r.describe(), contains('TextBlock'));
      expect(r.describe(), contains('Table'));
    });

    test('broken when a parsed card has duplicate JSON keys', () {
      // A Carousel with duplicate "pages" key. The jsonDecode keeps the last
      // value, so tryParseCardBody succeeds, but judgeReply detects the
      // duplicate via checkNoDuplicateJsonKeys and returns ok: false.
      const reply =
          '{"type":"Carousel","pages":[],"pages":[{"type":"Container",'
          '"items":[]}]}';
      final outcome = outcomeFor(reply);
      // Verify the server marked it broken before testing judgeShape.
      expect(
        outcome.ok,
        isFalse,
        reason: 'fixture should trigger duplicate-key',
      );
      expect(outcome.label, contains('duplicate-key'));

      final r = judgeShape(tableCase, outcome);
      expect(r.pass, isFalse);
      expect(r.label, startsWith('broken'));
      expect(r.found, contains('Carousel'));
    });
  });
}
