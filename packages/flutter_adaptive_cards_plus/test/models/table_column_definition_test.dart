import 'package:flutter_adaptive_cards_plus/src/models/table_column_definition.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TableColumnDefinition', () {
    test('creates from JSON with numeric width', () {
      final json = {'width': 2};
      final columnDef = TableColumnDefinition.fromJson(json);

      expect(columnDef.width, 2);
    });

    test('creates from JSON with string width', () {
      final json = {'width': '50px'};
      final columnDef = TableColumnDefinition.fromJson(json);

      expect(columnDef.width, '50px');
    });

    test('creates from JSON with null width', () {
      final json = <String, dynamic>{};
      final columnDef = TableColumnDefinition.fromJson(json);

      expect(columnDef.width, isNull);
    });

    test('toJson includes width when set', () {
      const columnDef = TableColumnDefinition(width: 3);
      final json = columnDef.toJson();

      expect(json['width'], 3);
    });

    test('toJson excludes width when null', () {
      const columnDef = TableColumnDefinition();
      final json = columnDef.toJson();

      expect(json.containsKey('width'), isFalse);
    });

    test('equality works correctly', () {
      const columnDef1 = TableColumnDefinition(width: 2);
      const columnDef2 = TableColumnDefinition(width: 2);
      const columnDef3 = TableColumnDefinition(width: 3);

      expect(columnDef1, equals(columnDef2));
      expect(columnDef1, isNot(equals(columnDef3)));
    });

    test('toString provides useful output', () {
      const columnDef = TableColumnDefinition(width: 1);
      expect(columnDef.toString(), contains('TableColumnDefinition'));
      expect(columnDef.toString(), contains('width'));
    });
  });
}
