import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/reference_resolver.dart';
import 'package:flutter_adaptive_cards_fs/src/responsive/adaptive_flow_layout.dart';
import 'package:flutter_adaptive_cards_fs/src/responsive/layout_selection.dart';
import 'package:flutter_adaptive_cards_fs/src/responsive/width_bucket.dart';

/// Lays out a container's [children] for the current width [bucket].
///
/// Chooses the best entry from [layouts] (see [selectLayout]). When the choice
/// is `Layout.Flow`, returns an [AdaptiveFlowLayout]; otherwise delegates to
/// [stackBuilder] (the caller's own stack widget — a `Column`, `Wrap`, etc.),
/// so non-Flow rendering is identical to before this helper existed. Callers
/// pass `ref.watch(cardWidthBucketProvider)` as [bucket] to reflow on resize.
Widget buildLayoutChildren({
  required List<dynamic>? layouts,
  required WidthBucket bucket,
  required ReferenceResolver styleResolver,
  required List<Widget> children,
  required Widget Function(List<Widget> children) stackBuilder,
}) {
  final selected = selectLayout(layouts, bucket);
  if (selected != null && selected['type'] == 'Layout.Flow') {
    return AdaptiveFlowLayout(
      layoutMap: selected,
      styleResolver: styleResolver,
      children: children,
    );
  }
  return stackBuilder(children);
}
