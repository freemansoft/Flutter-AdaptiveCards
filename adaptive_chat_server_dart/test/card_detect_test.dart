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

    test('leading/trailing decoration (=== headers) is stripped', () {
      const raw = '=== \n{"type":"TextBlock","text":"hi"}\n ===';
      expect(tryParseCardBody(raw), isNotNull);
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
