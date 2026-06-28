// RenderObject fields are private with public getters/setters (the Flutter
// idiom), so their constructor params cannot be initializing formals (named
// params cannot be private).
// ignore_for_file: prefer_initializing_formals

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/block_height.dart';

/// Builds a vertical stack where children whose JSON requests
/// `height: "stretch"` fill the available main-axis space — but only when the
/// stack is height-bounded.
///
/// [childMaps] is the raw element JSON, index-aligned with [children]. When the
/// incoming `maxHeight` is finite and at least one child is a stretch child,
/// stretch children grow to share the leftover main-axis space equally and the
/// rest keep their natural size. When the height is unbounded (the common
/// content-sized card body), `stretch` has nothing to fill, so the children
/// render at their natural size (`stretch` degrades to `auto`).
///
/// When no child requests `stretch` this returns a plain [Column] (identical to
/// the previous behavior); only the stretch case uses [RenderStretchColumn],
/// which — unlike a `LayoutBuilder`-based approach — reports intrinsic
/// dimensions and therefore works inside `IntrinsicHeight` (e.g. `ColumnSet`
/// columns and `Table` rows) without throwing.
Widget buildStretchableColumn({
  required List<Map<String, dynamic>> childMaps,
  required List<Widget> children,
  required MainAxisAlignment mainAxisAlignment,
  CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start,
  MainAxisSize mainAxisSize = MainAxisSize.max,
}) {
  final stretchFlags = [
    for (var i = 0; i < children.length; i++)
      i < childMaps.length && isStretchHeight(childMaps[i]),
  ];

  if (!stretchFlags.contains(true)) {
    return Column(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: children,
    );
  }

  // mainAxisAlignment is intentionally not forwarded: a stretch child consumes
  // all main-axis slack, so vertical alignment has no effect in this path.
  return _StretchColumn(
    crossAxisAlignment: crossAxisAlignment,
    mainAxisSize: mainAxisSize,
    stretchFlags: stretchFlags,
    children: children,
  );
}

double _atLeastZero(double value) => value < 0 ? 0 : value;

class _StretchParentData extends ContainerBoxParentData<RenderBox> {
  /// Whether this child requested `height: "stretch"`.
  bool stretch = false;
}

class _StretchColumn extends MultiChildRenderObjectWidget {
  const _StretchColumn({
    required this.crossAxisAlignment,
    required this.mainAxisSize,
    required this.stretchFlags,
    required super.children,
  });

  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;
  final List<bool> stretchFlags;

  @override
  RenderStretchColumn createRenderObject(BuildContext context) =>
      RenderStretchColumn(
        crossAxisAlignment: crossAxisAlignment,
        mainAxisSize: mainAxisSize,
        stretchFlags: stretchFlags,
        textDirection: Directionality.of(context),
      );

  @override
  void updateRenderObject(
    BuildContext context,
    RenderStretchColumn renderObject,
  ) {
    renderObject
      ..crossAxisAlignment = crossAxisAlignment
      ..mainAxisSize = mainAxisSize
      ..stretchFlags = stretchFlags
      ..textDirection = Directionality.of(context);
  }
}

/// A vertical stack that grows `height: "stretch"` children to fill leftover
/// main-axis space when bounded, and degrades them to their natural size when
/// the incoming `maxHeight` is unbounded.
///
/// Reports intrinsic dimensions (treating stretch children as `auto`), so it is
/// safe inside `IntrinsicHeight` — the context a plain `LayoutBuilder` cannot
/// support.
class RenderStretchColumn extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _StretchParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _StretchParentData> {
  /// Creates a stretch-aware vertical stack render object.
  RenderStretchColumn({
    required CrossAxisAlignment crossAxisAlignment,
    required MainAxisSize mainAxisSize,
    required List<bool> stretchFlags,
    required TextDirection textDirection,
  })  : _crossAxisAlignment = crossAxisAlignment,
        _mainAxisSize = mainAxisSize,
        _stretchFlags = stretchFlags,
        _textDirection = textDirection;

  /// Horizontal alignment of children (see [Column.crossAxisAlignment]).
  CrossAxisAlignment get crossAxisAlignment => _crossAxisAlignment;
  CrossAxisAlignment _crossAxisAlignment;
  set crossAxisAlignment(CrossAxisAlignment value) {
    if (_crossAxisAlignment == value) return;
    _crossAxisAlignment = value;
    markNeedsLayout();
  }

  /// Whether the stack tries to fill the bounded main axis (see
  /// [Column.mainAxisSize]).
  MainAxisSize get mainAxisSize => _mainAxisSize;
  MainAxisSize _mainAxisSize;
  set mainAxisSize(MainAxisSize value) {
    if (_mainAxisSize == value) return;
    _mainAxisSize = value;
    markNeedsLayout();
  }

  /// Per-child `height: "stretch"` flags, index-aligned with the children.
  List<bool> get stretchFlags => _stretchFlags;
  List<bool> _stretchFlags;
  set stretchFlags(List<bool> value) {
    _stretchFlags = value;
    markNeedsLayout();
  }

  /// Text direction used to resolve cross-axis `start`/`end`.
  TextDirection get textDirection => _textDirection;
  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (_textDirection == value) return;
    _textDirection = value;
    markNeedsLayout();
  }

  bool get _isRtl => _textDirection == TextDirection.rtl;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _StretchParentData) {
      child.parentData = _StretchParentData();
    }
  }

  void _assignFlags() {
    var i = 0;
    var child = firstChild;
    while (child != null) {
      (child.parentData! as _StretchParentData).stretch =
          i < _stretchFlags.length && _stretchFlags[i];
      child = childAfter(child);
      i++;
    }
  }

  // Intrinsics treat stretch children as `auto` (their natural size), matching
  // the unbounded degrade-to-auto behavior. There is no inter-child spacing
  // (separators live inside the children themselves).

  double _maxChildIntrinsic(double Function(RenderBox child) measure) {
    var value = 0.0;
    var child = firstChild;
    while (child != null) {
      value = math.max(value, measure(child));
      child = childAfter(child);
    }
    return value;
  }

  double _sumChildIntrinsic(double Function(RenderBox child) measure) {
    var value = 0.0;
    var child = firstChild;
    while (child != null) {
      value += measure(child);
      child = childAfter(child);
    }
    return value;
  }

  @override
  double computeMinIntrinsicWidth(double height) =>
      _maxChildIntrinsic((c) => c.getMinIntrinsicWidth(double.infinity));

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _maxChildIntrinsic((c) => c.getMaxIntrinsicWidth(double.infinity));

  @override
  double computeMinIntrinsicHeight(double width) =>
      _sumChildIntrinsic((c) => c.getMinIntrinsicHeight(width));

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _sumChildIntrinsic((c) => c.getMaxIntrinsicHeight(width));

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) =>
      defaultComputeDistanceToFirstActualBaseline(baseline);

  @override
  void performLayout() {
    _assignFlags();

    final bool heightBounded = constraints.maxHeight.isFinite;
    final bool widthBounded = constraints.maxWidth.isFinite;
    final bool crossStretch =
        _crossAxisAlignment == CrossAxisAlignment.stretch && widthBounded;

    BoxConstraints childConstraints({double? tightHeight}) {
      return BoxConstraints(
        minWidth: crossStretch ? constraints.maxWidth : 0,
        maxWidth: widthBounded ? constraints.maxWidth : double.infinity,
        minHeight: tightHeight ?? 0,
        maxHeight: tightHeight ?? double.infinity,
      );
    }

    final children = <RenderBox>[];
    var c = firstChild;
    while (c != null) {
      children.add(c);
      c = childAfter(c);
    }

    final stretchKids = <RenderBox>[
      for (final child in children)
        if ((child.parentData! as _StretchParentData).stretch && heightBounded)
          child,
    ];

    // Pass 1: lay out non-stretch children (and, when unbounded, stretch
    // children too) at their natural height.
    var nonFlexHeight = 0.0;
    var maxChildWidth = 0.0;
    for (final child in children) {
      if (stretchKids.contains(child)) continue;
      child.layout(childConstraints(), parentUsesSize: true);
      nonFlexHeight += child.size.height;
      maxChildWidth = math.max(maxChildWidth, child.size.width);
    }

    // Pass 2: distribute leftover space to stretch children equally.
    final double free =
        heightBounded ? _atLeastZero(constraints.maxHeight - nonFlexHeight) : 0;
    if (stretchKids.isNotEmpty) {
      final each = free / stretchKids.length;
      for (final child in stretchKids) {
        child.layout(childConstraints(tightHeight: each), parentUsesSize: true);
        maxChildWidth = math.max(maxChildWidth, child.size.width);
      }
    }

    final double width =
        crossStretch ? constraints.maxWidth : constraints.constrainWidth(maxChildWidth);

    final double childrenHeight =
        nonFlexHeight + (stretchKids.isNotEmpty ? free : 0.0);
    final double height = (_mainAxisSize == MainAxisSize.max && heightBounded)
        ? constraints.maxHeight
        : constraints.constrainHeight(childrenHeight);

    size = Size(width, height);

    // No main-axis free-space distribution: this render object only exists when
    // a stretch child is present, which consumes all slack when bounded; when
    // unbounded the stack sizes to its content. Either way there is no leftover
    // main-axis space, so children are positioned sequentially from the top.
    var y = 0.0;
    for (final child in children) {
      final pd = child.parentData! as _StretchParentData;
      double dx;
      switch (_crossAxisAlignment) {
        case CrossAxisAlignment.start:
        case CrossAxisAlignment.baseline:
          dx = _isRtl ? width - child.size.width : 0;
        case CrossAxisAlignment.end:
          dx = _isRtl ? 0 : width - child.size.width;
        case CrossAxisAlignment.center:
          dx = (width - child.size.width) / 2;
        case CrossAxisAlignment.stretch:
          dx = 0;
      }
      pd.offset = Offset(dx, y);
      y += child.size.height;
    }
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
