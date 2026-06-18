import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/reference_resolver.dart';

/// Renders a container's items as a wrapping `Layout.Flow` arrangement.
///
/// Items flow left-to-right and wrap to new rows as width allows, instead of
/// stacking vertically. `columnSpacing` / `rowSpacing` resolve through the same
/// HostConfig spacing tokens as other elements; `horizontalItemsAlignment` and
/// `verticalItemsAlignment` map to [Wrap] alignment.
///
/// Items size to their content by default (so they sit side-by-side rather than
/// each filling the row), clamped by optional `minItemWidth` / `maxItemWidth`
/// (logical pixels) from the layout JSON. The `itemFit` mode is not yet honored;
/// items always use the content-fit default.
class AdaptiveFlowLayout extends StatelessWidget {
  /// Creates a flow layout from a parsed `Layout.Flow` [layoutMap].
  const AdaptiveFlowLayout({
    required this.layoutMap,
    required this.styleResolver,
    required this.children,
    super.key,
  });

  /// The selected `Layout.Flow` object from the container's `layouts` array.
  final Map<String, dynamic> layoutMap;

  /// Resolver used to map spacing tokens to pixel gaps.
  final ReferenceResolver styleResolver;

  /// The container's item widgets to arrange.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final minItemWidth = _toDouble(layoutMap['minItemWidth']);
    final maxItemWidth = _toDouble(layoutMap['maxItemWidth']);
    return Wrap(
      spacing: styleResolver.resolveSpacing(
        layoutMap['columnSpacing'] as String?,
      ),
      runSpacing: styleResolver.resolveSpacing(
        layoutMap['rowSpacing'] as String?,
      ),
      alignment: _wrapAlignment(
        layoutMap['horizontalItemsAlignment'] as String?,
      ),
      crossAxisAlignment: _wrapCrossAlignment(
        layoutMap['verticalItemsAlignment'] as String?,
      ),
      children: [
        for (final child in children)
          _sizedItem(child, minItemWidth, maxItemWidth),
      ],
    );
  }

  /// Sizes a flow item to its content (so items sit side-by-side instead of
  /// each expanding to the full row), clamped to [minWidth]/[maxWidth] when set.
  Widget _sizedItem(Widget child, double? minWidth, double? maxWidth) {
    final content = IntrinsicWidth(child: child);
    if (minWidth == null && maxWidth == null) return content;
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: minWidth ?? 0.0,
        maxWidth: maxWidth ?? double.infinity,
      ),
      child: content,
    );
  }

  double? _toDouble(Object? value) =>
      value is num ? value.toDouble() : null;

  WrapAlignment _wrapAlignment(String? value) {
    switch (value) {
      case 'center':
        return WrapAlignment.center;
      case 'right':
        return WrapAlignment.end;
      default:
        return WrapAlignment.start;
    }
  }

  WrapCrossAlignment _wrapCrossAlignment(String? value) {
    switch (value) {
      case 'center':
        return WrapCrossAlignment.center;
      case 'bottom':
        return WrapCrossAlignment.end;
      default:
        return WrapCrossAlignment.start;
    }
  }
}
