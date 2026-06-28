import 'package:flutter_adaptive_cards_fs/src/responsive/width_bucket.dart';

/// Selects the best `layouts` entry for the current [bucket], or `null` to use
/// the implicit `Layout.Stack` default.
///
/// Containers and the card root body carry an optional `layouts` array (each
/// entry a layout object with a `type` and optional `targetWidth`). This picks
/// the most specific entry that applies at [bucket]:
/// exact-bucket `targetWidth` wins, then a matching relational `targetWidth`,
/// then a layout with no `targetWidth` (applies to all widths). Non-map entries
/// are ignored. Returns `null` when nothing applies so callers render a stack.
Map<String, dynamic>? selectLayout(
  List<dynamic>? layouts,
  WidthBucket bucket,
) {
  if (layouts == null || layouts.isEmpty) return null;

  Map<String, dynamic>? relationalMatch;
  int? relationalBestSpecificity;
  Map<String, dynamic>? defaultMatch;

  for (final raw in layouts) {
    if (raw is! Map) continue;
    final layout = Map<String, dynamic>.from(raw);
    final targetWidth = layout['targetWidth'] as String?;
    if (!targetWidthMatches(targetWidth, bucket)) continue;

    if (isExactBucketMatch(targetWidth, bucket)) {
      return layout;
    }
    if (targetWidth == null || targetWidth.trim().isEmpty) {
      defaultMatch ??= layout;
    } else {
      final specificity = relationalSpecificity(targetWidth);
      if (specificity != null &&
          (relationalBestSpecificity == null ||
              specificity < relationalBestSpecificity)) {
        relationalBestSpecificity = specificity;
        relationalMatch = layout;
      }
    }
  }

  return relationalMatch ?? defaultMatch;
}
