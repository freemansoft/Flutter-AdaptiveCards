import 'dart:math' as math;

import 'package:flutter_adaptive_cards_fs/src/responsive/area_grid_model.dart';

/// Total column count: the larger of the declared columns and the furthest
/// column reached by any area (`column + columnSpan - 1`).
int gridColumnCount({
  required int declaredColumns,
  required List<GridAreaModel> areas,
}) {
  var maxCol = declaredColumns;
  for (final a in areas) {
    maxCol = math.max(maxCol, a.column + a.columnSpan - 1);
  }
  return math.max(maxCol, 1);
}

/// Total row count: the furthest row reached by any area (`row + rowSpan - 1`).
int gridRowCount(List<GridAreaModel> areas) {
  var maxRow = 1;
  for (final a in areas) {
    maxRow = math.max(maxRow, a.row + a.rowSpan - 1);
  }
  return maxRow;
}

/// Resolves per-column pixel widths for [colCount] columns across
/// [availableWidth] (the content width already net of column spacing).
///
/// Declared `px` tracks take their fixed width; declared `%` tracks take that
/// percentage of [availableWidth]; any remaining (implied) columns split the
/// leftover space equally. Widths are clamped to >= 0.
List<double> resolveColumnWidths({
  required List<AreaGridTrack> columns,
  required int colCount,
  required double availableWidth,
}) {
  final widths = List<double>.filled(colCount, 0);
  var used = 0.0;
  for (var i = 0; i < colCount; i++) {
    if (i < columns.length) {
      final t = columns[i];
      final w = t.isPercent ? availableWidth * (t.value / 100.0) : t.value;
      widths[i] = math.max(0, w);
      used += widths[i];
    }
  }
  final impliedCount = colCount - columns.length;
  if (impliedCount > 0) {
    final each = math.max(0, (availableWidth - used) / impliedCount);
    for (var i = columns.length; i < colCount; i++) {
      widths[i] = each.toDouble();
    }
  }
  return widths;
}
