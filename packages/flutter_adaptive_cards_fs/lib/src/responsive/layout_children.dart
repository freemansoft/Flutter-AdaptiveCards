import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/reference_resolver.dart';
import 'package:flutter_adaptive_cards_fs/src/responsive/adaptive_area_grid.dart';
import 'package:flutter_adaptive_cards_fs/src/responsive/adaptive_flow_layout.dart';
import 'package:flutter_adaptive_cards_fs/src/responsive/area_grid_model.dart';
import 'package:flutter_adaptive_cards_fs/src/responsive/layout_selection.dart';
import 'package:flutter_adaptive_cards_fs/src/responsive/width_bucket.dart';

/// Lays out a container's [children] for the current width [bucket].
///
/// Chooses the best entry from [layouts] (see [selectLayout]): `Layout.Flow` →
/// [AdaptiveFlowLayout]; `Layout.AreaGrid` → [AdaptiveAreaGrid] (needs
/// [childMaps] — the raw item JSON, index-aligned with [children] — to read each
/// child's `grid.area`); otherwise delegates to [stackBuilder] (the caller's own
/// stack), so non-layout rendering is unchanged. Callers pass
/// `ref.watch(cardWidthBucketProvider)` as [bucket] to reflow on resize.
Widget buildLayoutChildren({
  required List<dynamic>? layouts,
  required WidthBucket bucket,
  required ReferenceResolver styleResolver,
  required List<Widget> children,
  required Widget Function(List<Widget> children) stackBuilder,
  List<Map<String, dynamic>> childMaps = const [],
}) {
  final selected = selectLayout(layouts, bucket);
  if (selected != null) {
    if (selected['type'] == 'Layout.Flow') {
      return AdaptiveFlowLayout(
        layoutMap: selected,
        styleResolver: styleResolver,
        children: children,
      );
    }
    if (selected['type'] == 'Layout.AreaGrid') {
      return AdaptiveAreaGrid(
        layout: AreaGridLayout.fromMap(selected),
        styleResolver: styleResolver,
        childMaps: childMaps,
        children: children,
      );
    }
  }
  return stackBuilder(children);
}
