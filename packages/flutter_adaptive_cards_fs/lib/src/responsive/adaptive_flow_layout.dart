import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/reference_resolver.dart';

/// Tracks `itemFit: "Fill"` warnings so each layout config logs at most once.
final Set<String> _loggedFillWarnings = <String>{};

/// Renders a container's items as a wrapping `Layout.Flow` arrangement.
///
/// Items flow left-to-right and wrap to new rows as width allows, instead of
/// stacking vertically. `columnSpacing` / `rowSpacing` resolve through the same
/// HostConfig spacing tokens as other elements; `horizontalItemsAlignment` and
/// `verticalItemsAlignment` map to [Wrap] alignment.
///
/// Item width follows the spec: `itemWidth` fixes each item's width; otherwise
/// `minItemWidth` / `maxItemWidth` clamp the content-fit width; with none set,
/// items take their natural size. `itemFit: "Fill"` (grow items to fill a row)
/// is not yet supported and is rendered as `"Fit"`.
///
/// Content-fit items are wrapped in [IntrinsicWidth] because several Adaptive
/// Card elements (e.g. `TextBlock`, which wraps its text in an expanding
/// [Align]) would otherwise stretch to the full row width inside a [Wrap] and
/// fail to flow. The trade-off: a content-fit item whose widget subtree can't
/// report an intrinsic width (a nested `Layout.Flow`/[Wrap] or a
/// [LayoutBuilder]-based element placed *directly* as a flow item) will throw;
/// give such an item an explicit `itemWidth` (which uses a [SizedBox] and skips
/// [IntrinsicWidth]) to size it safely.
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
    final itemWidth = _toPixels(layoutMap['itemWidth']);
    final minItemWidth = _toPixels(layoutMap['minItemWidth']);
    final maxItemWidth = _toPixels(layoutMap['maxItemWidth']);
    _warnUnsupportedItemFit();
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
          _sizedItem(child, itemWidth, minItemWidth, maxItemWidth),
      ],
    );
  }

  /// Applies the spec item-sizing rules.
  ///
  /// `itemWidth` (fixed) takes precedence and uses a [SizedBox] — no
  /// [IntrinsicWidth], so it also safely sizes items that can't report
  /// intrinsic dimensions. Otherwise the item is content-fit: wrapped in
  /// [IntrinsicWidth] so it shrinks to its natural width instead of filling the
  /// row (several elements — e.g. `TextBlock`, which wraps its text in an
  /// expanding [Align] — would otherwise stretch to the full [Wrap] width and
  /// stop flowing), and clamped by [ConstrainedBox] when `min`/`maxItemWidth`
  /// are present.
  Widget _sizedItem(
    Widget child,
    double? itemWidth,
    double? minWidth,
    double? maxWidth,
  ) {
    if (itemWidth != null) {
      if (minWidth != null || maxWidth != null) {
        developer.log(
          'Layout.Flow itemWidth is set; ignoring minItemWidth/maxItemWidth',
          name: 'responsive.adaptive_flow_layout',
        );
      }
      return SizedBox(width: itemWidth, child: child);
    }
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

  /// `itemFit: "Fill"` needs a custom row-packing layout (not expressible with
  /// [Wrap]); log once and fall back to the content-fit ("Fit") behavior.
  void _warnUnsupportedItemFit() {
    final itemFit = (layoutMap['itemFit'] as String?)?.trim().toLowerCase();
    if (itemFit == 'fill') {
      final key = layoutMap.toString();
      if (_loggedFillWarnings.add(key)) {
        developer.log(
          'Layout.Flow itemFit "Fill" is not supported; rendering as "Fit"',
          name: 'responsive.adaptive_flow_layout',
        );
      }
    }
  }

  /// Parses a spec `"<number>px"` string or a bare number to logical pixels;
  /// returns `null` for absent or malformed values.
  double? _toPixels(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) {
      final trimmed = value.trim();
      final body = trimmed.toLowerCase().endsWith('px')
          ? trimmed.substring(0, trimmed.length - 2).trim()
          : trimmed;
      return double.tryParse(body);
    }
    return null;
  }

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
