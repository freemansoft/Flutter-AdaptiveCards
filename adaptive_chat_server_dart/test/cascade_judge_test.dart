import 'package:test/test.dart';

// Relative: the probe lives outside lib/.
import '../tool/model_probes/cascade_ab.dart';

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

    test('treats a re-cased title as kept, not dropped', () {
      final result = judgeCascade(
        singleSelect(['New York']),
        multiSelect(['NEW YORK']),
      );
      expect(result.pass, isTrue);
    });

    test('reports which turn broke when turn 1 is not a card', () {
      final result = judgeCascade(
        'Here are your options: California, Texas.',
        multiSelect(['California', 'Texas']),
      );
      expect(result.pass, isFalse);
      expect(result.detail, startsWith('t1 '));
    });

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
