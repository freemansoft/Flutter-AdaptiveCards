import 'package:flutter/widgets.dart';

/// Maps an Adaptive Cards `Table` column `width` to a Flutter [TableColumnWidth].
///
/// Callers pass the raw `width` JSON value (a number or string). `"auto"` sizes
/// the column to its content; `"stretch"`, a missing value, or anything
/// unrecognized fills the remaining space (flex 1); a positive number is a flex
/// weight; `"Npx"` is a fixed pixel width. Keeping this pure (no widgets) lets
/// the width-mode branching be unit-tested without pumping a table.
TableColumnWidth mapColumnWidth(Object? width) {
  if (width is num) {
    return width > 0
        ? FlexColumnWidth(width.toDouble())
        : const FlexColumnWidth();
  }
  if (width is String) {
    final value = width.trim().toLowerCase();
    if (value == 'auto') return const IntrinsicColumnWidth();
    if (value == 'stretch') return const FlexColumnWidth();
    if (value.endsWith('px')) {
      final px = double.tryParse(value.substring(0, value.length - 2));
      if (px != null && px > 0) return FixedColumnWidth(px);
    }
  }
  return const FlexColumnWidth();
}

/// Parses an Adaptive Cards cell `minHeight` (e.g. `"80px"`) to a pixel value.
///
/// Returns null when the value is absent, unparseable, or non-positive so callers
/// can skip applying a constraint entirely.
double? parseCellMinHeightPx(String? minHeight) {
  if (minHeight == null) return null;
  final value = minHeight.trim().toLowerCase();
  final raw = value.endsWith('px')
      ? value.substring(0, value.length - 2)
      : value;
  final px = double.tryParse(raw);
  if (px == null || px <= 0) return null;
  return px;
}
