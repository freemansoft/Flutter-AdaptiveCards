import 'package:flutter_adaptive_template_fs/src/resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final nestedData = <String, dynamic>{
    'address': {'city': 'Redmond', 'state': 'WA'},
    'items': [
      {'name': 'Item 1'},
      {'name': 'Item 2'},
    ],
    'a': 1,
  };

  group('Resolver.resolve', () {
    test('returns null when data is null', () {
      expect(Resolver.resolve(null, 'any'), isNull);
    });

    test('returns data for empty or dot path', () {
      expect(Resolver.resolve(nestedData, ''), nestedData);
      expect(Resolver.resolve(nestedData, '.'), nestedData);
    });

    test('resolves dot-separated property chains', () {
      expect(Resolver.resolve(nestedData, 'address.city'), 'Redmond');
      expect(Resolver.resolve(nestedData, 'address.state'), 'WA');
      expect(Resolver.resolve(nestedData, 'a'), 1);
    });

    test('returns null for missing keys', () {
      expect(Resolver.resolve(nestedData, 'missing'), isNull);
      expect(Resolver.resolve(nestedData, 'address.zip'), isNull);
    });

    test('resolves array index then property', () {
      expect(Resolver.resolve(nestedData, 'items[0].name'), 'Item 1');
      expect(Resolver.resolve(nestedData, 'items[1].name'), 'Item 2');
    });

    test('returns null for out-of-range index', () {
      expect(Resolver.resolve(nestedData, 'items[99].name'), isNull);
      expect(Resolver.resolve(nestedData, 'items[-1].name'), isNull);
    });

    test('returns null for non-numeric index', () {
      expect(Resolver.resolve(nestedData, 'items[abc].name'), isNull);
    });

    test('returns null when indexing a non-list', () {
      expect(Resolver.resolve(nestedData, 'address[0]'), isNull);
      expect(Resolver.resolve(nestedData, 'a[0]'), isNull);
    });

    test('returns null when bracket property is missing', () {
      expect(Resolver.resolve(nestedData, 'missing[0]'), isNull);
    });

    test('does not resolve chained brackets in one segment', () {
      // Path is split on '.' only; "a[0][1]" is one segment with index "0][1".
      final data = <String, dynamic>{
        'a': [
          [1, 2],
        ],
      };
      expect(Resolver.resolve(data, 'a[0][1]'), isNull);
    });

    test('reuses template_test fixture shapes', () {
      final data = <String, dynamic>{
        'firstName': 'Matt',
        'address': {'city': 'Redmond', 'state': 'WA'},
        'items': [
          {'name': 'Item 1'},
          {'name': 'Item 2'},
        ],
      };

      expect(Resolver.resolve(data, 'firstName'), 'Matt');
      expect(Resolver.resolve(data, 'address.city'), 'Redmond');
      expect(Resolver.resolve(data, 'items[0].name'), 'Item 1');
    });
  });
}
