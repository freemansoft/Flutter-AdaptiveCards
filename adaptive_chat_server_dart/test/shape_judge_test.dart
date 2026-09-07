import 'package:test/test.dart';

// Relative: both files live outside lib/.
import '../tool/model_probes/probe_support.dart';
import '../tool/model_probes/shape_cases.dart';

// judgeShape is the classifier every shape_ab.dart score and every
// ModelBehavior.md shape-coverage figure is built from: it turns a raw reply
// into pass/fail plus a label, and that label decides which "kind of wrong"
// a finding names (no-input vs wrong-shape vs prose vs broken). A mistake
// here would not fail loudly — it would just misfile a run's failures under
// the wrong cause, which a passing test suite elsewhere would never surface.
// These tests drive judgeShape through outcomeFor's judgeReply(reply, 0) —
// the server's own card/prose verdict — rather than a hand-built
// ProbeOutcome, so the label boundaries pinned here are the ones the real
// probe actually returns.

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
    // The baseline: a reply matching the requested type must not get caught
    // by any of the special-case branches (no-input, broken, ...) below.
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

    // The failure a model shows when it answers with a card but forgets the
    // case actually asked for an input — a different bug, and a different
    // fix, from sending the wrong input widget (below).
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

    // Same wrong-shape path for a case that never required an input at all —
    // confirms requiresInput isn't accidentally load-bearing for this label.
    test('wrong-shape for a non-input case with the wrong element', () {
      final r = judgeShape(
        tableCase,
        outcomeFor('{"type":"TextBlock","text":"Jupiter is big","wrap":true}'),
      );
      expect(r.pass, isFalse);
      expect(r.label, 'wrong-shape');
    });

    // The model answered honestly in the wrong format (no card attempted at
    // all), which must read as a different failure from a card that used
    // the wrong element.
    test('prose when a card was expected and clean prose came back', () {
      final r = judgeShape(tableCase, outcomeFor('Jupiter is the largest.'));
      expect(r.pass, isFalse);
      expect(r.label, 'prose');
      expect(r.found, isEmpty);
    });

    // judgeShape defers entirely to the server's own parse verdict here
    // rather than re-deciding what counts as malformed.
    test('broken when the reply is malformed JSON', () {
      final r = judgeShape(
        tableCase,
        outcomeFor('{"type":"Table","rows":[{"type":"TableRow"'),
      );
      expect(r.pass, isFalse);
      expect(r.label, startsWith('broken'));
    });

    test('malformed-JSON label is not doubled with "broken: broken"', () {
      // Regression: judgeReply already returns 'broken: <reason>' for a
      // parse failure, and judgeShape used to blindly re-prefix every
      // outcome.label with 'broken: ', producing 'broken: broken: invalid
      // JSON...'. brokenLabel() must recognize the label is already
      // prefixed and leave it alone.
      final r = judgeShape(
        tableCase,
        outcomeFor('{"type":"Table","rows":[{"type":"TableRow"'),
      );
      expect(r.pass, isFalse);
      expect(r.label, startsWith('broken'));
      expect(r.label, isNot(contains('broken: broken')));
    });

    // A model that wraps card JSON in prose leaves the user staring at raw
    // JSON text; judgeReply already scores that broken, and judgeShape must
    // not override it with a passing prose label just because no clean card
    // parsed out.
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

    // The control's happy path: prose is what this case wants, so it must
    // earn an explicit pass, not just fail to trigger unwanted-card.
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

    // The control's own failure mode: a model reaches for a card even though
    // the case should stay prose. Distinct from broken, which covers a card
    // that also failed to parse cleanly.
    test('unwanted-card when the control case returns a card', () {
      final r = judgeShape(
        proseCase,
        outcomeFor('{"type":"TextBlock","text":"Blue scatters","wrap":true}'),
      );
      expect(r.pass, isFalse);
      expect(r.label, 'unwanted-card');
    });

    test('broken when the control case gets a prose-wrapped card', () {
      // Regression: the negative-control branch used to decide on
      // `body == null` alone, so a reply that failed to parse as a card for
      // any reason — including prose wrapping a card, which judgeReply marks
      // broken — scored prose-ok. It must score broken instead, exactly like
      // the general branch.
      final r = judgeShape(
        proseCase,
        outcomeFor(
          'Sure, here you go:\n\n```json\n'
          '{"type":"TextBlock","text":"hi","wrap":true}\n```',
        ),
      );
      expect(r.pass, isFalse);
      expect(r.label, startsWith('broken'));
    });

    // describe() is what a human reads in probe output; a wrong-shape line
    // that doesn't name what actually came back is useless for tracking down
    // which element a model reached for instead.
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
