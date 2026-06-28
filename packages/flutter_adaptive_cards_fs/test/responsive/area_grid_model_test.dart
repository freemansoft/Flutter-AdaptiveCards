import 'package:flutter_adaptive_cards_fs/src/responsive/area_grid_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses areas with defaults', () {
    final layout = AreaGridLayout.fromMap(const {
      'type': 'Layout.AreaGrid',
      'columns': [20, '40px', 40],
      'areas': [
        {'name': 'a', 'columnSpan': 2},
        {'name': 'b', 'column': 3, 'row': 2, 'rowSpan': 2},
      ],
    });
    expect(layout.columns.length, 3);
    expect(layout.columns[0].isPercent, isTrue);
    expect(layout.columns[0].value, 20);
    expect(layout.columns[1].isPercent, isFalse); // px
    expect(layout.columns[1].value, 40);
    final a = layout.areas[0];
    expect(a.name, 'a');
    expect(a.column, 1); // default
    expect(a.columnSpan, 2);
    expect(a.row, 1); // default
    expect(a.rowSpan, 1); // default
    final b = layout.areas[1];
    expect(b.column, 3);
    expect(b.row, 2);
    expect(b.rowSpan, 2);
  });

  test('tolerates missing/garbage fields', () {
    final layout = AreaGridLayout.fromMap(const {'type': 'Layout.AreaGrid'});
    expect(layout.columns, isEmpty);
    expect(layout.areas, isEmpty);
    final clamped = AreaGridLayout.fromMap(const {
      'areas': [
        {'name': 'x', 'column': 0, 'columnSpan': 0, 'row': -1, 'rowSpan': 0},
      ],
    });
    final x = clamped.areas.single;
    expect(x.column, 1); // clamped to >= 1
    expect(x.columnSpan, 1);
    expect(x.row, 1);
    expect(x.rowSpan, 1);
  });
}
