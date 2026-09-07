import 'dart:convert';

import 'package:adaptive_chat_server_dart/src/card_detect.dart';
import 'package:test/test.dart';

// Ordinary behavioral unit test of card_detect.dart's parsing/repair
// heuristics — not a data-validation check. A local model's reply is
// freeform text that may or may not be a card, wrapped in whichever
// combination of code fences, decoration, or missing brackets that model
// happens to produce; tryParseCardBody / cardParseFailureReason decide
// whether to render it as a card or fall back to prose. Regressing any of
// these heuristics either rejects a reply that should have rendered (raw
// JSON shown to the user) or, worse, silently corrupts a reply that already
// parsed (the ```dart-inside-a-card-string case below is a real failure this
// suite caught). The fence/decoration/bracket-repair heuristics are also
// deliberately narrow — several cases here exist to pin down where a repair
// must NOT fire, not just where it should.
void main() {
  group('tryParseCardBody — accepted shapes', () {
    // Shape 1 from card_detect.dart's doc comment: the full-card wrapper most
    // models emit when asked outright for a card.
    test('a full AdaptiveCard object returns its body', () {
      const raw =
          '{"type":"AdaptiveCard","body":[{"type":"TextBlock","text":"hi"}]}';
      expect(tryParseCardBody(raw), [
        {'type': 'TextBlock', 'text': 'hi'},
      ]);
    });

    // Shape 2: some models skip the AdaptiveCard wrapper and answer with the
    // body array directly.
    test('a bare non-empty array of objects is returned as-is', () {
      const raw =
          '[{"type":"TextBlock","text":"hi"},{"type":"Badge","text":"New"}]';
      expect(tryParseCardBody(raw), [
        {'type': 'TextBlock', 'text': 'hi'},
        {'type': 'Badge', 'text': 'New'},
      ]);
    });

    // Shape 3: a lone element with no wrapper is a usable reply, not a
    // malformed one.
    test('a single element object is wrapped as a one-item body', () {
      const raw = '{"type":"Input.ChoiceSet","id":"x"}';
      expect(tryParseCardBody(raw), [
        {'type': 'Input.ChoiceSet', 'id': 'x'},
      ]);
    });

    // The common case: a model dutifully wraps otherwise-valid JSON in a
    // fenced code block anyway.
    test('a balanced ```json fence is stripped before parsing', () {
      const raw = '```json\n{"type":"TextBlock","text":"hi"}\n```';
      expect(tryParseCardBody(raw), [
        {'type': 'TextBlock', 'text': 'hi'},
      ]);
    });

    // Some models fence without naming the language; the fence regex must
    // not require one.
    test('a bare ``` fence (no language tag) is stripped', () {
      const raw = '```\n{"type":"TextBlock","text":"hi"}\n```';
      expect(tryParseCardBody(raw), isNotNull);
    });

    // A model that opens a fence and forgets to close it must not be
    // rejected outright.
    test('an unbalanced opening fence is stripped', () {
      const raw = '```json\n{"type":"TextBlock","text":"hi"}';
      expect(tryParseCardBody(raw), isNotNull);
    });

    // Mirror of the missing-opening-fence case: either edge can go missing
    // independently of the other.
    test('an unbalanced closing fence is stripped', () {
      const raw = '{"type":"TextBlock","text":"hi"}\n```';
      expect(tryParseCardBody(raw), isNotNull);
    });

    test('a card whose own text contains a Markdown code fence survives', () {
      // Verbatim reply from qwen3.6:27b-coding-nvfp4 for "show me a Dart
      // snippet ... with a short explanation above it". It is valid JSON —
      // every newline correctly escaped — but the reply is a single line, so
      // the unbalanced-closing-fence heuristic used to match the ```dart
      // that opens the snippet *inside* the string and delete everything
      // from there to the end, truncating the JSON mid-string.
      // jsonEncode reproduces the model's exact wire form: one line, every
      // newline escaped as \n.
      final raw = jsonEncode({
        'type': 'TextBlock',
        'text':
            'Use `dart:convert` to decode the file contents into a '
            '`Map`, then access the key directly:\n\n'
            '```dart\n'
            "import 'dart:convert';\n\n"
            'void main() {\n'
            '  final data = jsonDecode(json) as Map<String, dynamic>;\n'
            "  print(data['name']);\n"
            '}\n'
            '```',
        'wrap': true,
      });
      expect(raw, isNot(contains('\n')), reason: 'model emits a single line');
      final body = tryParseCardBody(raw);
      expect(body, isNotNull, reason: 'valid JSON must never be mangled');
      expect(body!.single['type'], 'TextBlock');
      expect(body.single['text'], contains('```dart'));
      expect(cardParseFailureReason(raw), isNull);
    });

    test('a fenced reply whose card text also contains a fence survives', () {
      // The repair heuristic must still work when it is genuinely needed:
      // a real wrapping fence around a card that itself mentions ```dart.
      const raw =
          '```json\n{"type":"TextBlock","text":"run ```dart main()``` now"}\n'
          '```';
      final body = tryParseCardBody(raw);
      expect(body, isNotNull);
      expect(body!.single['text'], contains('```dart'));
    });

    // Some models wrap the JSON in Markdown-style banner lines instead of a
    // fence; those need peeling too, not just fences.
    test('leading/trailing decoration (=== headers) is stripped', () {
      const raw = '=== \n{"type":"TextBlock","text":"hi"}\n ===';
      expect(tryParseCardBody(raw), isNotNull);
    });

    // Chart elements take the same single-element wrapping path as any other
    // type — no chart-specific branch here to fall out of sync with.
    test('a bare Chart.Pie element is wrapped as a one-item body', () {
      const raw = '{"type":"Chart.Pie","data":[{"title":"North","value":30}]}';
      expect(tryParseCardBody(raw), [
        {
          'type': 'Chart.Pie',
          'data': [
            {'title': 'North', 'value': 30},
          ],
        },
      ]);
    });

    test('top-level objects missing their array brackets are wrapped', () {
      // Verbatim shape from qwen2.5-coder:7b once the card system prompt
      // taught it to answer "explain this code" with TextBlock + CodeBlock:
      // it emits the two elements comma-separated but drops the enclosing
      // [ ]. That is an array missing its brackets and nothing else, so it
      // is repairable without guessing at intent.
      const raw =
          '```json\n'
          '{\n  "type": "TextBlock",\n  "text": "Reads a file.",\n'
          '  "wrap": true\n},\n'
          '{\n  "type": "CodeBlock",\n  "codeSnippet": "print(1)",\n'
          '  "language": "dart"\n}\n'
          '```';
      expect(tryParseCardBody(raw), [
        {'type': 'TextBlock', 'text': 'Reads a file.', 'wrap': true},
        {'type': 'CodeBlock', 'codeSnippet': 'print(1)', 'language': 'dart'},
      ]);
    });

    // The bracket-repair path must fire on its own; it cannot depend on fence
    // stripping having run first to trigger it.
    test('unbracketed top-level objects work without a fence too', () {
      const raw =
          '{"type":"TextBlock","text":"hi"},'
          '{"type":"Badge","text":"New"}';
      expect(tryParseCardBody(raw), [
        {'type': 'TextBlock', 'text': 'hi'},
        {'type': 'Badge', 'text': 'New'},
      ]);
    });

    // A chart nested in a full card unwraps the same as any other element
    // type — the AdaptiveCard branch does not special-case charts.
    test('a full AdaptiveCard wrapping a chart returns its body', () {
      const raw =
          '{"type":"AdaptiveCard","body":[{"type":"Chart.VerticalBar",'
          '"data":[{"x":"Mon","y":12}]}]}';
      expect(tryParseCardBody(raw), [
        {
          'type': 'Chart.VerticalBar',
          'data': [
            {'x': 'Mon', 'y': 12},
          ],
        },
      ]);
    });
  });

  group('tryParseCardBody — rejected shapes', () {
    // Only fence/decoration wrapping is stripped; free-standing prose around
    // the JSON is not, so a genuinely mixed reply stays rejected rather than
    // silently reduced to whatever JSON it happens to contain.
    test('surrounding prose is not stripped, so it is rejected', () {
      const raw = 'Sure, here you go: {"type":"TextBlock","text":"hi"}';
      expect(tryParseCardBody(raw), isNull);
    });

    // Baseline negative: an ordinary Markdown answer must never be mistaken
    // for a card attempt.
    test('plain prose with no JSON returns null', () {
      expect(tryParseCardBody('Just a normal reply.'), isNull);
    });

    // An empty body is not a renderable card and must not be waved through
    // as a valid-but-empty one.
    test('an empty array returns null', () {
      expect(tryParseCardBody('[]'), isNull);
    });

    // A scalar sitting beside real elements means the model malformed the
    // array; that reply is not safely coercible into a card.
    test('a mixed array (non-object element) returns null', () {
      expect(
        tryParseCardBody('[{"type":"TextBlock"}, "not an object"]'),
        isNull,
      );
    });

    // No `type` key rules out all three accepted shapes; it is not element
    // data, so it must not be wrapped as if it were.
    test('a dict with no type key returns null', () {
      expect(tryParseCardBody('{"foo":"bar"}'), isNull);
    });

    // Same empty-body rule as the bare-array case above, but reached through
    // the wrapped-card path instead.
    test('a full AdaptiveCard with an empty body returns null', () {
      expect(tryParseCardBody('{"type":"AdaptiveCard","body":[]}'), isNull);
    });

    // A malformed body inside a full-card wrapper must fail closed, not
    // throw a cast error past the caller.
    test(
      'a full AdaptiveCard whose body contains a non-object element '
      'returns null instead of throwing',
      () {
        expect(
          tryParseCardBody(
            '{"type":"AdaptiveCard","body":'
            '[{"type":"TextBlock"}, "not an object"]}',
          ),
          isNull,
        );
      },
    );

    // A bare number or string is valid JSON but never a card — guards
    // against a parsed-but-not-Map/List value falling through unchecked.
    test('a scalar JSON value returns null', () {
      expect(tryParseCardBody('42'), isNull);
      expect(tryParseCardBody('"just a string"'), isNull);
    });

    // A parse failure must degrade to null, not propagate a FormatException
    // up to callers that only expect a body-or-null result.
    test('invalid JSON returns null', () {
      expect(tryParseCardBody('{not valid json'), isNull);
    });

    test('bracket repair does not rescue trailing prose after a card', () {
      // The failure the bracket repair must NOT paper over: a card followed
      // by an explanation is a mixed reply, not a bracketless array.
      const raw =
          '{"type":"CodeBlock","codeSnippet":"print(1)"}\n\n'
          'This card shows a Dart snippet.';
      expect(tryParseCardBody(raw), isNull);
    });
  });

  group('replyWrapsCardInProse', () {
    // The failure mode this function exists to catch: a reply with a usable
    // card buried inside it is not itself usable, but a shape-detector that
    // only asks "is there a card in here" would file it as a pass.
    test('a preamble followed by a fenced card is flagged', () {
      const raw =
          'Sure, here you go:\n\n'
          '```json\n{"type":"TextBlock","text":"hi","wrap":true}\n```';
      expect(replyWrapsCardInProse(raw), isTrue);
      // It is not a usable card either — that is the whole problem.
      expect(tryParseCardBody(raw), isNull);
    });

    // A clean fenced card is not "wrapped in prose" — it already renders
    // fine, so flagging it here would be a false positive.
    test('a fenced card with nothing around it is not flagged', () {
      const raw = '```json\n{"type":"TextBlock","text":"hi","wrap":true}\n```';
      expect(replyWrapsCardInProse(raw), isFalse);
      expect(tryParseCardBody(raw), isNotNull);
    });

    // A legitimate Markdown answer with an unrelated code sample must not be
    // mistaken for a buried card just because it has a fence.
    test('genuine prose containing a non-card code fence is not flagged', () {
      const raw = 'Use dart:io:\n\n```dart\nvoid main() {}\n```';
      expect(replyWrapsCardInProse(raw), isFalse);
    });

    // Baseline: nothing resembling a fence means nothing to flag.
    test('plain prose with no fence at all is not flagged', () {
      expect(replyWrapsCardInProse('Just a normal reply.'), isFalse);
    });
  });

  group('cardParseFailureReason', () {
    // A diagnostic-only helper must stay silent on the success path — it is
    // not the thing that decides whether the card renders.
    test('returns null for a valid card', () {
      expect(
        cardParseFailureReason(
          '{"type":"AdaptiveCard","body":[{"type":"TextBlock"}]}',
        ),
        isNull,
      );
    });

    // Ordinary prose is not a failed card attempt, so it earns no diagnostic
    // either — telling "never tried" apart from "tried and failed" is the
    // whole point of this helper over a bare tryParseCardBody-is-null check.
    test('returns null for plain prose (not an attempted card)', () {
      expect(cardParseFailureReason('Just a normal reply.'), isNull);
    });

    // The case worth logging: text that opened like JSON but did not parse —
    // a bare tryParseCardBody result of null tells an operator nothing about
    // why.
    test('returns a reason for invalid JSON that looked like a card', () {
      expect(
        cardParseFailureReason('{"type": "AdaptiveCard", "body": [}'),
        isNotNull,
      );
    });

    // Valid-but-unusable JSON (empty body, missing type, mixed array) is a
    // different diagnosis than invalid JSON, and an operator debugging a
    // bad reply needs to tell the two apart.
    test('returns a reason for valid JSON that is not a renderable card', () {
      expect(
        cardParseFailureReason('{"type":"AdaptiveCard","body":[]}'),
        isNotNull,
      );
    });
  });
}
