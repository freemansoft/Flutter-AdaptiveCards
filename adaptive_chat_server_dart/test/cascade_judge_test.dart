import 'package:test/test.dart';

// Relative: the probe lives outside lib/.
import '../tool/model_probes/cascade_ab.dart';

// judgeCascade is the only check that catches a model reformatting a choice
// list correctly (single-select -> multi-select) while silently dropping
// items off it — see cascade_ab.dart's doc comment: shape-only scoring
// would call that a pass. These tests pin the three-part pass condition and
// the failure-attribution (t1 vs t2, which choices got dropped) a probe run
// reports, driving judgeCascade/readChoiceSet directly against string
// replies rather than a live model.

/// A single-select choice set offering [titles].
String singleSelect(List<String> titles) => _set(titles, multi: false);

/// The same set widened to multi-select.
String multiSelect(List<String> titles) => _set(titles, multi: true);

/// Builds a minimal card body carrying one choice set.
String _set(List<String> titles, {required bool multi}) {
  final choices = titles.map((t) => '{"title":"$t","value":"$t"}').join(',');
  return '[{"type":"TextBlock","text":"Pick","wrap":true},'
      '{"type":"Input.ChoiceSet","id":"x",'
      '"isMultiSelect":$multi,"choices":[$choices]}]';
}

void main() {
  group('judgeCascade', () {
    // The mechanism cascade_ab exists to prove works at all: the same list
    // widened to multi-select, nothing added or dropped.
    test('passes when turn 2 widens the same list', () {
      final result = judgeCascade(
        singleSelect(['California', 'Texas', 'Florida']),
        multiSelect(['California', 'Texas', 'Florida']),
      );
      expect(result.pass, isTrue);
      expect(result.detail, contains('kept 3/3'));
    });

    test('fails when turn 2 silently drops a choice', () {
      // The failure this probe exists for: the format cascades correctly and
      // the list quietly shrinks, which shape-only scoring calls a pass.
      final result = judgeCascade(
        singleSelect(['California', 'Texas', 'Florida', 'New York']),
        multiSelect(['California', 'Texas']),
      );
      expect(result.pass, isFalse);
      expect(result.detail, contains('dropped 2/4'));
      expect(result.detail, contains('florida'));
      expect(result.detail, contains('new york'));
    });

    // A model can keep every choice and still ignore the actual request if
    // it never flips isMultiSelect; this condition must catch that on its
    // own, independent of whether anything was dropped.
    test('fails when turn 2 stays single-select', () {
      final result = judgeCascade(
        singleSelect(['Debug', 'Info']),
        singleSelect(['Debug', 'Info']),
      );
      expect(result.pass, isFalse);
      expect(result.detail, contains('not-multi'));
    });

    test('passes when turn 2 adds choices but keeps every original', () {
      // Widening the question is not the failure being hunted; losing the
      // original list is.
      final result = judgeCascade(
        singleSelect(['Dev', 'Prod']),
        multiSelect(['Dev', 'Prod', 'Staging']),
      );
      expect(result.pass, isTrue);
      expect(result.detail, contains('+1 new'));
    });

    // Case is not part of a choice's identity to a user; comparing
    // case-sensitively would score a harmless re-casing as real data loss.
    test('treats a re-cased title as kept, not dropped', () {
      final result = judgeCascade(
        singleSelect(['New York']),
        multiSelect(['NEW YORK']),
      );
      expect(result.pass, isTrue);
    });

    // Attributing the failure to the right turn matters for probe output:
    // "t1" vs "t2" is the difference between a model that can't produce a
    // choice set at all and one that only breaks on the follow-up edit.
    test('reports which turn broke when turn 1 is not a card', () {
      final result = judgeCascade(
        'Here are your options: California, Texas.',
        multiSelect(['California', 'Texas']),
      );
      expect(result.pass, isFalse);
      expect(result.detail, startsWith('t1 '));
    });

    // Same attribution, the other side: turn 1 was fine, so the report must
    // not blame it.
    test('reports turn 2 when only turn 2 is unusable', () {
      final result = judgeCascade(
        singleSelect(['Dev', 'Prod']),
        '{"type":"AdaptiveCard","body":'
        '[{"type":"TextBlock","text":"Dev, Prod"}]}',
      );
      expect(result.pass, isFalse);
      expect(result.detail, startsWith('t2 '));
      expect(result.detail, contains('no-choiceset'));
    });

    // An empty choice list technically has nothing to drop, so the
    // drop-count check alone would call it a pass; this catches the
    // degenerate case separately.
    test('a choice set with no choices is a failure, not an empty pass', () {
      final result = judgeCascade(
        '[{"type":"Input.ChoiceSet","id":"x","choices":[]}]',
        multiSelect(['Dev']),
      );
      expect(result.pass, isFalse);
      expect(result.detail, contains('no choices'));
    });
  });

  group('readChoiceSet', () {
    // The spec's default matters here because turn 1 legitimately omits the
    // key; reading a missing key as true would falsely accuse turn 1 of
    // never asking for a single answer.
    test('reads an omitted isMultiSelect as false, per the spec', () {
      final reading = readChoiceSet(
        '[{"type":"Input.ChoiceSet","id":"x",'
        '"choices":[{"title":"A","value":"a"}]}]',
      );
      expect(reading.ok, isTrue);
      expect(reading.multiSelect, isFalse);
      expect(reading.titles, equals(['A']));
    });
  });

  group('a stalled call is not prose', () {
    test('an empty reply would otherwise be judged prose', () {
      // The defect this guards. A timed-out call returns '', and judgeCascade
      // cannot tell that from a model that chose Markdown — it reported six
      // of granite4.1:3b's timeouts as "t1 prose (no card attempted)", which
      // reads as an answer the model never gave. cascade_ab now checks the
      // outcome label before judging; this pins the ambiguity the judge has.
      final result = judgeCascade('', '');
      expect(result.pass, isFalse);
      expect(result.detail, contains('prose'));
      expect(
        result.detail,
        isNot(contains('timeout')),
        reason: 'the judge sees only text, so the caller must name the stall',
      );
    });
  });

  group('a stalled call is not prose', () {
    test('an empty reply is judged prose, not a stall', () {
      // The defect this guards. A timed-out call returns '', and judgeCascade
      // cannot tell that from a model that chose Markdown — it reported six of
      // granite4.1:3b's timeouts as "t1 prose (no card attempted)", which reads
      // as an answer the model never gave. cascade_ab now inspects the outcome
      // label before judging; this pins the ambiguity that makes it necessary.
      final result = judgeCascade('', '');
      expect(result.pass, isFalse);
      expect(result.detail, contains('prose'));
      expect(
        result.detail,
        isNot(contains('timeout')),
        reason: 'the judge sees only text, so the caller must name the stall',
      );
    });
  });
}
