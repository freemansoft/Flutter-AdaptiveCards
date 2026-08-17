import 'package:adaptive_chat_server_dart/src/card_detect.dart';
import 'package:test/test.dart';

// Relative: probe_support lives outside lib/, so there is no package: URI.
import '../tool/model_probes/probe_support.dart';

/// Parses [raw] the way every probe does, failing the test if it is not a
/// card — so a broken fixture reads as a fixture bug, not a walker bug.
List<Map<String, dynamic>> body(String raw) {
  final parsed = tryParseCardBody(raw);
  expect(parsed, isNotNull, reason: 'fixture is not a parseable card: $raw');
  return parsed!;
}

void main() {
  group('collectElementTypes', () {
    test('finds types at the top level of a bare array', () {
      final types = collectElementTypes(
        body(
          '[{"type":"TextBlock","text":"hi","wrap":true},'
          '{"type":"Input.Date","id":"when"}]',
        ),
      );
      expect(types, containsAll(<String>['TextBlock', 'Input.Date']));
    });

    test('finds a type nested inside Carousel pages', () {
      final types = collectElementTypes(
        body(
          '{"type":"Carousel","pages":[{"type":"CarouselPage","items":'
          '[{"type":"Input.ChoiceSet","id":"x","choices":[]}]}]}',
        ),
      );
      expect(types, contains('Input.ChoiceSet'));
      expect(types, contains('Carousel'));
    });

    test('finds a type nested inside Table cells', () {
      final types = collectElementTypes(
        body(
          '{"type":"Table","columns":[{"width":1}],"rows":[{"type":"TableRow",'
          '"cells":[{"type":"TableCell","items":[{"type":"Badge",'
          '"text":"New"}]}]}]}',
        ),
      );
      expect(types, contains('Badge'));
      expect(types, contains('Table'));
    });

    test('finds a type nested inside ColumnSet columns', () {
      final types = collectElementTypes(
        body(
          '{"type":"ColumnSet","columns":[{"type":"Column","width":1,"items":'
          '[{"type":"Rating","value":4,"max":5}]}]}',
        ),
      );
      expect(types, contains('Rating'));
    });

    test('finds types inside the full AdaptiveCard wrapper', () {
      final types = collectElementTypes(
        body(
          '{"type":"AdaptiveCard","version":"1.5","body":'
          '[{"type":"Chart.Gauge","value":72,"min":0,"max":100}]}',
        ),
      );
      expect(types, contains('Chart.Gauge'));
    });

    test('a single bare element object yields its own type', () {
      final types = collectElementTypes(body('{"type":"Input.Time","id":"t"}'));
      expect(types, equals(<String>{'Input.Time'}));
    });
  });

  group('cardContainsAnyType', () {
    late List<Map<String, dynamic>> twoElements;

    setUp(() {
      twoElements = body(
        '[{"type":"TextBlock","text":"Pick one","wrap":true}, '
        '{"type":"Input.ChoiceSet","id":"c","choices":[]}]',
      );
    });

    test('true when the single wanted type is present', () {
      expect(cardContainsAnyType(twoElements, {'Input.ChoiceSet'}), isTrue);
    });

    test('true when ANY of several wanted types is present', () {
      // The alternatives rule: the model picks among acceptable shapes.
      expect(
        cardContainsAnyType(twoElements, {'Chart.Pie', 'Input.ChoiceSet'}),
        isTrue,
      );
    });

    test('false when none of the wanted types is present', () {
      expect(cardContainsAnyType(twoElements, {'Carousel', 'Table'}), isFalse);
    });

    test('false for an empty wanted set', () {
      expect(cardContainsAnyType(twoElements, <String>{}), isFalse);
    });
  });
}
