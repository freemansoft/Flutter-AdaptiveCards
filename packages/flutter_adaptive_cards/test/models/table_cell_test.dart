import 'package:flutter_adaptive_cards/src/models/table_cell.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TableCellModel', () {
    test('fromJson creates TableCellModel with all properties', () {
      final json = {
        'items': [
          {'type': 'TextBlock', 'text': 'Cell content'},
        ],
        'style': 'emphasis',
        'verticalContentAlignment': 'center',
        'horizontalContentAlignment': 'left',
        'id': 'cell1',
        'isVisible': true,
      };

      final cell = TableCellModel.fromJson(json);

      expect(cell.items.length, 1);
      expect(cell.items[0]['type'], 'TextBlock');
      expect(cell.style, 'emphasis');
      expect(cell.verticalContentAlignment, 'center');
      expect(cell.horizontalContentAlignment, 'left');
      expect(cell.id, 'cell1');
      expect(cell.isVisible, true);
    });

    test('fromJson handles minimal properties', () {
      final json = {
        'items': <Map<String, dynamic>>[],
      };

      final cell = TableCellModel.fromJson(json);

      expect(cell.items, isEmpty);
      expect(cell.style, isNull);
      expect(cell.id, isNull);
    });

    test('fromJson handles missing items', () {
      final json = <String, dynamic>{};

      final cell = TableCellModel.fromJson(json);

      expect(cell.items, isEmpty);
    });

    test('toJson includes all non-null properties', () {
      const cell = TableCellModel(
        items: [
          {'type': 'TextBlock', 'text': 'Content'},
        ],
        style: 'default',
        id: 'cell2',
        isVisible: false,
      );

      final json = cell.toJson();

      expect(json['items'], isNotNull);
      expect(json['style'], 'default');
      expect(json['id'], 'cell2');
      expect(json['isVisible'], false);
    });

    test('toJson excludes null properties', () {
      const cell = TableCellModel(
        items: [],
      );

      final json = cell.toJson();

      expect(json.containsKey('style'), isFalse);
      expect(json.containsKey('id'), isFalse);
      expect(json.containsKey('isVisible'), isFalse);
    });

    test('round-trip serialization works', () {
      const original = TableCellModel(
        items: [
          {'type': 'TextBlock', 'text': 'Test'},
        ],
        style: 'accent',
        verticalContentAlignment: 'top',
        id: 'test-cell',
      );

      final json = original.toJson();
      final restored = TableCellModel.fromJson(json);

      expect(restored.items.length, original.items.length);
      expect(restored.style, original.style);
      expect(
        restored.verticalContentAlignment,
        original.verticalContentAlignment,
      );
      expect(restored.id, original.id);
    });

    test('toString returns expected format', () {
      const cell = TableCellModel(
        items: [
          {'type': 'TextBlock'},
          {'type': 'Image'},
        ],
      );

      expect(cell.toString(), 'TableCellModel(items: 2 items)');
    });

    test('handles complex items', () {
      final json = {
        'items': [
          {
            'type': 'Container',
            'items': [
              {'type': 'TextBlock', 'text': 'Nested'},
            ],
          },
        ],
      };

      final cell = TableCellModel.fromJson(json);

      expect(cell.items.length, 1);
      expect(cell.items[0]['type'], 'Container');
      expect(cell.items[0]['items'], isNotNull);
    });
  });
}
