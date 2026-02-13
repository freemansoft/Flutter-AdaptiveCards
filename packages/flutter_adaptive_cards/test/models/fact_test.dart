import 'package:flutter_adaptive_cards/src/models/fact.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Fact', () {
    test('fromJson creates Fact with all properties', () {
      final json = {
        'title': 'Name',
        'value': 'John Doe',
      };

      final fact = Fact.fromJson(json);

      expect(fact.title, 'Name');
      expect(fact.value, 'John Doe');
    });

    test('fromJson handles missing properties', () {
      final json = <String, dynamic>{};

      final fact = Fact.fromJson(json);

      expect(fact.title, '');
      expect(fact.value, '');
    });

    test('toJson includes all properties', () {
      const fact = Fact(
        title: 'Age',
        value: '30',
      );

      final json = fact.toJson();

      expect(json['title'], 'Age');
      expect(json['value'], '30');
    });

    test('round-trip serialization works', () {
      const original = Fact(
        title: 'Location',
        value: 'New York',
      );

      final json = original.toJson();
      final restored = Fact.fromJson(json);

      expect(restored.title, original.title);
      expect(restored.value, original.value);
    });

    test('equality works correctly', () {
      const fact1 = Fact(title: 'Name', value: 'John');
      const fact2 = Fact(title: 'Name', value: 'John');
      const fact3 = Fact(title: 'Name', value: 'Jane');

      expect(fact1, equals(fact2));
      expect(fact1, isNot(equals(fact3)));
    });

    test('hashCode works correctly', () {
      const fact1 = Fact(title: 'Name', value: 'John');
      const fact2 = Fact(title: 'Name', value: 'John');

      expect(fact1.hashCode, equals(fact2.hashCode));
    });

    test('toString returns expected format', () {
      const fact = Fact(title: 'Status', value: 'Active');

      expect(fact.toString(), 'Fact(title: Status, value: Active)');
    });
  });
}
