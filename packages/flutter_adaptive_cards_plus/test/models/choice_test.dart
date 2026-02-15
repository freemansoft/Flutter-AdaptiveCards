import 'package:flutter_adaptive_cards_plus/src/models/choice.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Choice', () {
    test('fromJson creates Choice with all properties', () {
      final json = {
        'title': 'Red Color',
        'value': 'red',
      };

      final choice = Choice.fromJson(json);

      expect(choice.title, 'Red Color');
      expect(choice.value, 'red');
    });

    test('fromJson handles value as non-string', () {
      final json = {
        'title': 'Number One',
        'value': 1,
      };

      final choice = Choice.fromJson(json);

      expect(choice.title, 'Number One');
      expect(choice.value, '1');
    });

    test('fromJson handles missing properties', () {
      final json = <String, dynamic>{};

      final choice = Choice.fromJson(json);

      expect(choice.title, '');
      expect(choice.value, '');
    });

    test('toJson includes all properties', () {
      const choice = Choice(
        title: 'Blue Color',
        value: 'blue',
      );

      final json = choice.toJson();

      expect(json['title'], 'Blue Color');
      expect(json['value'], 'blue');
    });

    test('round-trip serialization works', () {
      const original = Choice(
        title: 'Green Color',
        value: 'green',
      );

      final json = original.toJson();
      final restored = Choice.fromJson(json);

      expect(restored.title, original.title);
      expect(restored.value, original.value);
    });

    test('equality works correctly', () {
      const choice1 = Choice(title: 'Option A', value: 'a');
      const choice2 = Choice(title: 'Option A', value: 'a');
      const choice3 = Choice(title: 'Option B', value: 'b');

      expect(choice1, equals(choice2));
      expect(choice1, isNot(equals(choice3)));
    });

    test('hashCode works correctly', () {
      const choice1 = Choice(title: 'Option A', value: 'a');
      const choice2 = Choice(title: 'Option A', value: 'a');

      expect(choice1.hashCode, equals(choice2.hashCode));
    });

    test('toString returns expected format', () {
      const choice = Choice(title: 'Small Size', value: 'S');

      expect(choice.toString(), 'Choice(title: Small Size, value: S)');
    });
  });
}
