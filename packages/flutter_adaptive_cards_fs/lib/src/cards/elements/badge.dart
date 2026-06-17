import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards_fs/src/additional.dart';
import 'package:flutter_adaptive_cards_fs/src/riverpod/providers.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/adaptive_image_utils.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Renders the Adaptive Cards **Badge** element (text and optional icon).
///
/// See https://adaptivecards.io/explorer/Badge.html
class AdaptiveBadge extends ConsumerStatefulWidget with AdaptiveElementWidgetMixin {
  /// Creates a badge from [adaptiveMap] JSON.
  AdaptiveBadge({
    required this.adaptiveMap,
  }) : super(key: generateAdaptiveWidgetKey(adaptiveMap)) {
    id = loadId(adaptiveMap);
  }

  @override
  final Map<String, dynamic> adaptiveMap;

  @override
  late final String id;

  @override
  AdaptiveBadgeState createState() => AdaptiveBadgeState();
}

/// State for [AdaptiveBadge]; resolves colors and layout from HostConfig.
class AdaptiveBadgeState extends ConsumerState<AdaptiveBadge>
    with AdaptiveElementMixin, AdaptiveVisibilityMixin, ProviderScopeMixin {
  @override
  Widget build(BuildContext context) {
    final resolved = ref.watch(resolvedElementProvider(id));
    final text = (resolved?['text'] as String?) ?? (adaptiveMap['text'] as String?);
    final iconUrl = (resolved?['iconUrl'] as String?) ?? (adaptiveMap['iconUrl'] as String?);
    final appearance =
        adaptiveMap['appearance']?.toString().toLowerCase() ?? 'filled';
    final size = adaptiveMap['size']?.toString().toLowerCase() ?? 'medium';
    final tooltip = adaptiveMap['tooltip'] as String?;
    final iconAlignment =
        adaptiveMap['iconAlignment']?.toString().toLowerCase() ?? 'left';

    final resolver = styleResolver;
    final Color backgroundColor =
        resolver.resolveBadgeBackgroundColor(
          colorStyle: style ?? 'default',
          appearance: appearance,
        ) ??
        resolver.resolveContainerBackgroundColor(style: 'default') ??
        Colors.transparent;
    final Color textColor =
        resolver.resolveBadgeForegroundColor(
          colorStyle: style ?? 'default',
          appearance: appearance,
        ) ??
        resolver.resolveContainerForegroundColor(style: 'default') ??
        Colors.black;

    // Resolve subtle vs non-subtle via HostConfig if possible,
    // but for now hardcode based on "style"

    Widget? iconWidget;
    if (iconUrl != null) {
      iconWidget = AdaptiveImageUtils.getImage(
        iconUrl,
        height: 16,
        width: 16,
        semanticsLabel: text,
      );
    }

    final List<Widget> children = [];
    if (iconAlignment == 'left' && iconWidget != null) {
      children.add(iconWidget);
      if (text != null) children.add(const SizedBox(width: 4));
    }

    if (text != null) {
      children.add(
        Text(
          text,
          style: TextStyle(
            color: textColor,
            fontSize: resolver.resolveBadgeFontSize(size),
          ),
        ),
      );
    }

    if (iconAlignment == 'right' && iconWidget != null) {
      if (text != null) children.add(const SizedBox(width: 4));
      children.add(iconWidget);
    }

    Widget badge = Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12), // Pill shape
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );

    if (tooltip != null) {
      badge = Tooltip(message: tooltip, child: badge);
    }

    return Visibility(
      visible: isVisible,
      child: SeparatorElement(
        adaptiveMap: adaptiveMap,
        child: badge,
      ),
    );
  }
}
