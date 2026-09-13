/// A single column track of a `Layout.AreaGrid`: either a percentage of the
/// available width (`isPercent == true`) or a fixed pixel width.
class const AreaGridTrack({
  /// The numeric width (percent points when [isPercent], else logical pixels).
  required final double value,

  /// Whether [value] is a percentage of available width (vs. fixed pixels).
  required final bool isPercent,
}) {
  /// Creates a column track with a [value] interpreted per [isPercent].
  this;

  /// Parses one `columns` entry: a number → percent; a `"<n>px"` string →
  /// pixels.
  ///
  /// Returns `null` for unparseable entries; the solver treats the shortfall as
  /// implied equal-share columns.
  static AreaGridTrack? fromJson(Object? raw) {
    if (raw is num) {
      return AreaGridTrack(value: raw.toDouble(), isPercent: true);
    }
    if (raw is String) {
      final t = raw.trim();
      final isPx = t.toLowerCase().endsWith('px');
      final body = isPx ? t.substring(0, t.length - 2).trim() : t;
      final n = double.tryParse(body);
      if (n == null) return null;
      return AreaGridTrack(value: n, isPercent: !isPx);
    }
    return null;
  }
}

/// A named placement region in a `Layout.AreaGrid`. Indices are 1-based.
class const GridAreaModel({
  /// Area name; matched against an element's `grid.area`.
  required final String name,

  /// 1-based start column (clamped to >= 1).
  required final int column,

  /// Number of columns spanned (clamped to >= 1).
  required final int columnSpan,

  /// 1-based start row (clamped to >= 1).
  required final int row,

  /// Number of rows spanned (clamped to >= 1).
  required final int rowSpan,
}) {
  /// Creates a named area at a 1-based [column]/[row] with the given spans.
  this;

  /// Parses one `areas` entry, applying spec defaults (column/row 1, spans 1)
  /// and clamping non-positive values to 1.
  factory fromJson(Map<String, dynamic> json) => GridAreaModel(
    name: (json['name'] as String?) ?? '',
    column: _posInt(json['column'], 1),
    columnSpan: _posInt(json['columnSpan'], 1),
    row: _posInt(json['row'], 1),
    rowSpan: _posInt(json['rowSpan'], 1),
  );

  static int _posInt(Object? v, int fallback) {
    final n = v is num ? v.toInt() : fallback;
    return n < 1 ? 1 : n;
  }
}

/// Parsed `Layout.AreaGrid` object (tracks, named areas, spacing tokens).
class const AreaGridLayout({
  /// Declared column tracks (may be fewer than the grid's total columns).
  required final List<AreaGridTrack> columns,

  /// Named areas elements are placed into via `grid.area`.
  required final List<GridAreaModel> areas,

  /// Spacing token between columns (HostConfig spacing name; resolved by
  /// widget).
  required final String? columnSpacing,

  /// Spacing token between rows (HostConfig spacing name; resolved by widget).
  required final String? rowSpacing,
}) {
  /// Creates a parsed AreaGrid layout.
  this;

  /// Parses a selected `Layout.AreaGrid` map. Unparseable `columns` entries are
  /// dropped (the solver treats the shortfall as implied equal-share columns).
  factory fromMap(Map<String, dynamic> map) {
    final cols = <AreaGridTrack>[];
    for (final c in (map['columns'] as List<dynamic>? ?? const [])) {
      final t = AreaGridTrack.fromJson(c);
      if (t != null) cols.add(t);
    }
    final areas = <GridAreaModel>[];
    for (final a in (map['areas'] as List<dynamic>? ?? const [])) {
      if (a is Map) {
        areas.add(GridAreaModel.fromJson(Map<String, dynamic>.from(a)));
      }
    }
    return AreaGridLayout(
      columns: cols,
      areas: areas,
      columnSpacing: map['columnSpacing'] as String?,
      rowSpacing: map['rowSpacing'] as String?,
    );
  }
}
