// RenderObject fields are private with public getters/setters (the Flutter
// idiom), so their constructor params cannot be initializing formals (named
// params cannot be private).
// ignore_for_file: prefer_initializing_formals

import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_adaptive_cards_fs/src/reference_resolver.dart';
import 'package:flutter_adaptive_cards_fs/src/responsive/area_grid_model.dart';
import 'package:flutter_adaptive_cards_fs/src/responsive/area_grid_solver.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/block_height.dart';

/// Placement + stretch flag for one placed grid child (1-based indices).
class AreaGridPlacement {
  /// Creates a placement spanning [columnSpan]×[rowSpan] from ([column], [row]).
  const AreaGridPlacement({
    required this.column,
    required this.columnSpan,
    required this.row,
    required this.rowSpan,
    required this.stretch,
  });

  /// 1-based start column.
  final int column;

  /// Number of columns spanned.
  final int columnSpan;

  /// 1-based start row.
  final int row;

  /// Number of rows spanned.
  final int rowSpan;

  /// Whether the child requested `height: "stretch"` (fills its cell height).
  final bool stretch;
}

/// Renders a container's children as a `Layout.AreaGrid`.
///
/// Children whose `grid.area` matches a named area are placed (and spanned) by a
/// custom [RenderAdaptiveAreaGrid]; children with a missing or unknown
/// `grid.area` are not dropped — they render in a fallback [Column] below the
/// grid (and are logged), mirroring the fail-open `targetWidth` philosophy.
class AdaptiveAreaGrid extends StatelessWidget {
  /// Creates an AreaGrid for [children] using the parsed [layout].
  const AdaptiveAreaGrid({
    required this.layout,
    required this.styleResolver,
    required this.childMaps,
    required this.children,
    super.key,
  });

  /// Parsed `Layout.AreaGrid` (columns, areas, spacing).
  final AreaGridLayout layout;

  /// Resolves HostConfig spacing tokens to pixels.
  final ReferenceResolver styleResolver;

  /// Raw item JSON, index-aligned with [children].
  final List<Map<String, dynamic>> childMaps;

  /// The container's already-built child widgets.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final areasByName = {for (final a in layout.areas) a.name: a};
    final colCount = gridColumnCount(
      declaredColumns: layout.columns.length,
      areas: layout.areas,
    );
    final rowCount = gridRowCount(layout.areas);

    final placed = <Widget>[];
    final placements = <AreaGridPlacement>[];
    final unplaced = <Widget>[];

    for (var i = 0; i < children.length; i++) {
      final map = i < childMaps.length
          ? childMaps[i]
          : const <String, dynamic>{};
      final areaName = map['grid.area'] as String?;
      final area = areaName == null ? null : areasByName[areaName];
      if (area == null) {
        if (areaName != null) {
          developer.log(
            'grid.area "$areaName" matches no area; rendering below the grid',
            name: 'responsive.area_grid',
          );
        }
        unplaced.add(children[i]);
        continue;
      }
      placed.add(children[i]);
      placements.add(
        AreaGridPlacement(
          column: area.column,
          columnSpan: area.columnSpan,
          row: area.row,
          rowSpan: area.rowSpan,
          stretch: isStretchHeight(map),
        ),
      );
    }

    final grid = placed.isEmpty
        ? const SizedBox.shrink()
        : _AreaGridRenderWidget(
            columns: layout.columns,
            colCount: colCount,
            rowCount: rowCount,
            columnSpacing: styleResolver.resolveSpacing(layout.columnSpacing),
            rowSpacing: styleResolver.resolveSpacing(layout.rowSpacing),
            placements: placements,
            children: placed,
          );

    if (unplaced.isEmpty) return grid;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [grid, ...unplaced],
    );
  }
}

class _AreaGridParentData extends ContainerBoxParentData<RenderBox> {
  AreaGridPlacement? placement;
}

class _AreaGridRenderWidget extends MultiChildRenderObjectWidget {
  const _AreaGridRenderWidget({
    required this.columns,
    required this.colCount,
    required this.rowCount,
    required this.columnSpacing,
    required this.rowSpacing,
    required this.placements,
    required super.children,
  });

  final List<AreaGridTrack> columns;
  final int colCount;
  final int rowCount;
  final double columnSpacing;
  final double rowSpacing;
  final List<AreaGridPlacement> placements;

  @override
  RenderAdaptiveAreaGrid createRenderObject(BuildContext context) =>
      RenderAdaptiveAreaGrid(
        columns: columns,
        colCount: colCount,
        rowCount: rowCount,
        columnSpacing: columnSpacing,
        rowSpacing: rowSpacing,
        placements: placements,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    RenderAdaptiveAreaGrid renderObject,
  ) {
    renderObject
      ..columns = columns
      ..colCount = colCount
      ..rowCount = rowCount
      ..columnSpacing = columnSpacing
      ..rowSpacing = rowSpacing
      ..placements = placements;
  }
}

double _atLeastZero(double value) => value < 0 ? 0 : value;

/// Custom grid layout: resolves column widths, sizes rows (content + spans),
/// fills `height:stretch` cells to their row band, and positions each child.
class RenderAdaptiveAreaGrid extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _AreaGridParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _AreaGridParentData> {
  /// Creates the AreaGrid render object.
  RenderAdaptiveAreaGrid({
    required List<AreaGridTrack> columns,
    required int colCount,
    required int rowCount,
    required double columnSpacing,
    required double rowSpacing,
    required List<AreaGridPlacement> placements,
  }) : _columns = columns,
       _colCount = colCount,
       _rowCount = rowCount,
       _columnSpacing = columnSpacing,
       _rowSpacing = rowSpacing,
       _placements = placements;

  /// Declared column tracks.
  List<AreaGridTrack> get columns => _columns;
  List<AreaGridTrack> _columns;
  set columns(List<AreaGridTrack> v) {
    _columns = v;
    markNeedsLayout();
  }

  /// Total column count (declared + implied).
  int get colCount => _colCount;
  int _colCount;
  set colCount(int v) {
    if (_colCount == v) return;
    _colCount = v;
    markNeedsLayout();
  }

  /// Total row count.
  int get rowCount => _rowCount;
  int _rowCount;
  set rowCount(int v) {
    if (_rowCount == v) return;
    _rowCount = v;
    markNeedsLayout();
  }

  /// Pixel gap between columns.
  double get columnSpacing => _columnSpacing;
  double _columnSpacing;
  set columnSpacing(double v) {
    if (_columnSpacing == v) return;
    _columnSpacing = v;
    markNeedsLayout();
  }

  /// Pixel gap between rows.
  double get rowSpacing => _rowSpacing;
  double _rowSpacing;
  set rowSpacing(double v) {
    if (_rowSpacing == v) return;
    _rowSpacing = v;
    markNeedsLayout();
  }

  /// Per-child placement, in child order.
  List<AreaGridPlacement> get placements => _placements;
  List<AreaGridPlacement> _placements;
  set placements(List<AreaGridPlacement> v) {
    _placements = v;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _AreaGridParentData) {
      child.parentData = _AreaGridParentData();
    }
  }

  /// Assigns placements to children by order.
  void _assignPlacements() {
    var i = 0;
    var child = firstChild;
    while (child != null) {
      (child.parentData! as _AreaGridParentData).placement =
          i < _placements.length ? _placements[i] : null;
      child = childAfter(child);
      i++;
    }
  }

  @override
  void performLayout() {
    _assignPlacements();
    final maxWidth = constraints.maxWidth;
    final availableWidth = maxWidth - _columnSpacing * (_colCount - 1);
    final colWidths = resolveColumnWidths(
      columns: _columns,
      colCount: _colCount,
      availableWidth: availableWidth.isFinite ? availableWidth : 0,
    );

    double cellWidth(AreaGridPlacement p) {
      var w = 0.0;
      for (
        var c = p.column - 1;
        c < p.column - 1 + p.columnSpan && c < colWidths.length;
        c++
      ) {
        w += colWidths[c];
      }
      return w + _columnSpacing * (p.columnSpan - 1);
    }

    final childList = <RenderBox>[];
    var child = firstChild;
    while (child != null) {
      childList.add(child);
      child = (child.parentData! as _AreaGridParentData).nextSibling;
    }

    // Pass 1: measure non-stretch children; seed single-row heights.
    final rowHeights = List<double>.filled(_rowCount, 0);
    for (final c in childList) {
      final p = (c.parentData! as _AreaGridParentData).placement;
      if (p == null || p.stretch) continue; // stretch deferred to pass 2
      c.layout(
        BoxConstraints.tightFor(width: cellWidth(p)),
        parentUsesSize: true,
      );
      if (p.rowSpan == 1) {
        final r = p.row - 1;
        if (r >= 0 && r < _rowCount) {
          rowHeights[r] = rowHeights[r] > c.size.height
              ? rowHeights[r]
              : c.size.height;
        }
      }
    }

    // Pass 1b: grow rows so multi-row non-stretch children fit.
    for (final c in childList) {
      final p = (c.parentData! as _AreaGridParentData).placement;
      if (p == null || p.stretch || p.rowSpan == 1) continue;
      var spanned = _rowSpacing * (p.rowSpan - 1);
      for (var r = p.row - 1; r < p.row - 1 + p.rowSpan && r < _rowCount; r++) {
        spanned += rowHeights[r];
      }
      final deficit = c.size.height - spanned;
      if (deficit > 0) {
        final add = deficit / p.rowSpan;
        for (
          var r = p.row - 1;
          r < p.row - 1 + p.rowSpan && r < _rowCount;
          r++
        ) {
          rowHeights[r] += add;
        }
      }
    }

    // Row y-offsets.
    final rowOffsets = List<double>.filled(_rowCount, 0);
    var y = 0.0;
    for (var r = 0; r < _rowCount; r++) {
      rowOffsets[r] = y;
      y += rowHeights[r] + (r < _rowCount - 1 ? _rowSpacing : 0);
    }
    final totalHeight = y;

    // Column x-offsets.
    final colOffsets = List<double>.filled(_colCount, 0);
    var x = 0.0;
    for (var c = 0; c < _colCount; c++) {
      colOffsets[c] = x;
      x += colWidths[c] + (c < _colCount - 1 ? _columnSpacing : 0);
    }

    double cellHeight(AreaGridPlacement p) {
      var h = _rowSpacing * (p.rowSpan - 1);
      for (var r = p.row - 1; r < p.row - 1 + p.rowSpan && r < _rowCount; r++) {
        h += rowHeights[r];
      }
      return h;
    }

    // Pass 2: lay out stretch children to full cell height; position everyone.
    for (final c in childList) {
      final pd = c.parentData! as _AreaGridParentData;
      final p = pd.placement;
      if (p == null) {
        pd.offset = Offset.zero;
        c.layout(const BoxConstraints.tightFor(width: 0, height: 0));
        continue;
      }
      if (p.stretch) {
        c.layout(
          BoxConstraints.tightFor(
            width: cellWidth(p),
            height: _atLeastZero(cellHeight(p)),
          ),
        );
      }
      final colIdx = (p.column - 1).clamp(0, _colCount - 1);
      final rowIdx = (p.row - 1).clamp(0, _rowCount - 1);
      pd.offset = Offset(colOffsets[colIdx], rowOffsets[rowIdx]);
    }

    final outWidth = maxWidth.isFinite ? maxWidth : x;
    size = constraints.constrain(Size(outWidth, totalHeight));
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    defaultPaint(context, offset);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }
}
