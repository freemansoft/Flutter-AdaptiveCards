import 'package:flutter_adaptive_cards_fs/src/responsive/area_grid_model.dart';
import 'package:flutter_adaptive_cards_fs/src/responsive/area_grid_solver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('grid dimensions from areas (max index + span)', () {
    final areas = [
      const GridAreaModel(name: 'a', column: 1, columnSpan: 2, row: 1, rowSpan: 1),
      const GridAreaModel(name: 'b', column: 3, columnSpan: 1, row: 2, rowSpan: 2),
    ];
    expect(gridColumnCount(declaredColumns: 0, areas: areas), 3);
    expect(gridRowCount(areas), 3); // row 2 + rowSpan 2 - 1
  });

  test('column widths: percent of available, px fixed, implied split remainder',
      () {
    final cols = [
      const AreaGridTrack(value: 50, isPercent: true), // 50% of 200 = 100
      const AreaGridTrack(value: 40, isPercent: false), // 40px
    ];
    // colCount 3 → one implied column gets the remainder.
    final widths = resolveColumnWidths(
      columns: cols,
      colCount: 3,
      availableWidth: 200,
    );
    expect(widths, [100, 40, 60]); // 200 - 100 - 40 = 60 for the implied col
  });

  test('all implied columns split equally', () {
    final widths = resolveColumnWidths(
      columns: const [],
      colCount: 4,
      availableWidth: 200,
    );
    expect(widths, [50, 50, 50, 50]);
  });

  test('negative remainder clamps implied columns to 0', () {
    final widths = resolveColumnWidths(
      columns: const [AreaGridTrack(value: 300, isPercent: false)],
      colCount: 2,
      availableWidth: 200,
    );
    expect(widths, [300, 0]);
  });
}
