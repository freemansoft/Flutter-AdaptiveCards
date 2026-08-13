import 'dart:convert';

import 'package:adaptive_chat_server_dart/src/card_detect.dart';
import 'package:test/test.dart';

void main() {
  group('tryParseCardBody — accepted shapes', () {
    test('a full AdaptiveCard object returns its body', () {
      const raw =
          '{"type":"AdaptiveCard","body":[{"type":"TextBlock","text":"hi"}]}';
      expect(tryParseCardBody(raw), [
        {'type': 'TextBlock', 'text': 'hi'},
      ]);
    });

    test('a bare non-empty array of objects is returned as-is', () {
      const raw =
          '[{"type":"TextBlock","text":"hi"},{"type":"Badge","text":"New"}]';
      expect(tryParseCardBody(raw), [
        {'type': 'TextBlock', 'text': 'hi'},
        {'type': 'Badge', 'text': 'New'},
      ]);
    });

    test('a single element object is wrapped as a one-item body', () {
      const raw = '{"type":"Input.ChoiceSet","id":"x"}';
      expect(tryParseCardBody(raw), [
        {'type': 'Input.ChoiceSet', 'id': 'x'},
      ]);
    });

    test('a balanced ```json fence is stripped before parsing', () {
      const raw = '```json\n{"type":"TextBlock","text":"hi"}\n```';
      expect(tryParseCardBody(raw), [
        {'type': 'TextBlock', 'text': 'hi'},
      ]);
    });

    test('a bare ``` fence (no language tag) is stripped', () {
      const raw = '```\n{"type":"TextBlock","text":"hi"}\n```';
      expect(tryParseCardBody(raw), isNotNull);
    });

    test('an unbalanced opening fence is stripped', () {
      const raw = '```json\n{"type":"TextBlock","text":"hi"}';
      expect(tryParseCardBody(raw), isNotNull);
    });

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
        'text': 'Use `dart:convert` to decode the file contents into a '
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

    test('leading/trailing decoration (=== headers) is stripped', () {
      const raw = '=== \n{"type":"TextBlock","text":"hi"}\n ===';
      expect(tryParseCardBody(raw), isNotNull);
    });

    test('a bare Chart.Pie element is wrapped as a one-item body', () {
      const raw =
          '{"type":"Chart.Pie","data":[{"title":"North","value":30}]}';
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
      const raw = '```json\n'
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

    test('unbracketed top-level objects work without a fence too', () {
      const raw = '{"type":"TextBlock","text":"hi"},'
          '{"type":"Badge","text":"New"}';
      expect(tryParseCardBody(raw), [
        {'type': 'TextBlock', 'text': 'hi'},
        {'type': 'Badge', 'text': 'New'},
      ]);
    });

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
    test('surrounding prose is not stripped, so it is rejected', () {
      const raw = 'Sure, here you go: {"type":"TextBlock","text":"hi"}';
      expect(tryParseCardBody(raw), isNull);
    });

    test('plain prose with no JSON returns null', () {
      expect(tryParseCardBody('Just a normal reply.'), isNull);
    });

    test('an empty array returns null', () {
      expect(tryParseCardBody('[]'), isNull);
    });

    test('a mixed array (non-object element) returns null', () {
      expect(
        tryParseCardBody('[{"type":"TextBlock"}, "not an object"]'),
        isNull,
      );
    });

    test('a dict with no type key returns null', () {
      expect(tryParseCardBody('{"foo":"bar"}'), isNull);
    });

    test('a full AdaptiveCard with an empty body returns null', () {
      expect(tryParseCardBody('{"type":"AdaptiveCard","body":[]}'), isNull);
    });

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

    test('a scalar JSON value returns null', () {
      expect(tryParseCardBody('42'), isNull);
      expect(tryParseCardBody('"just a string"'), isNull);
    });

    test('invalid JSON returns null', () {
      expect(tryParseCardBody('{not valid json'), isNull);
    });

    test('bracket repair does not rescue trailing prose after a card', () {
      // The failure the bracket repair must NOT paper over: a card followed
      // by an explanation is a mixed reply, not a bracketless array.
      const raw = '{"type":"CodeBlock","codeSnippet":"print(1)"}\n\n'
          'This card shows a Dart snippet.';
      expect(tryParseCardBody(raw), isNull);
    });
  });

  group('cardParseFailureReason', () {
    test('returns null for a valid card', () {
      expect(
        cardParseFailureReason(
          '{"type":"AdaptiveCard","body":[{"type":"TextBlock"}]}',
        ),
        isNull,
      );
    });

    test('returns null for plain prose (not an attempted card)', () {
      expect(cardParseFailureReason('Just a normal reply.'), isNull);
    });

    test('returns a reason for invalid JSON that looked like a card', () {
      expect(
        cardParseFailureReason('{"type": "AdaptiveCard", "body": [}'),
        isNotNull,
      );
    });

    test('returns a reason for valid JSON that is not a renderable card', () {
      expect(
        cardParseFailureReason('{"type":"AdaptiveCard","body":[]}'),
        isNotNull,
      );
    });
  });
}
