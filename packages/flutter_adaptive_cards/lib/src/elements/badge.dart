import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards/src/additional.dart';
import 'package:flutter_adaptive_cards/src/hostconfig/badge_styles_config.dart';
import 'package:flutter_adaptive_cards/src/hostconfig/fallback_configs.dart';
import 'package:flutter_adaptive_cards/src/hostconfig/font_color_config.dart';
import 'package:flutter_adaptive_cards/src/inherited_reference_resolver.dart';
import 'package:flutter_adaptive_cards/src/utils/adaptive_image_utils.dart';
import 'package:flutter_adaptive_cards/src/utils/utils.dart';

class AdaptiveBadge extends StatefulWidget with AdaptiveElementWidgetMixin {
  AdaptiveBadge({
    required this.adaptiveMap,
  }) : super(key: generateWidgetKey(adaptiveMap)) {
    id = loadId(adaptiveMap);
  }

  @override
  final Map<String, dynamic> adaptiveMap;

  @override
  late final String id;

  @override
  AdaptiveBadgeState createState() => AdaptiveBadgeState();
}

class AdaptiveBadgeState extends State<AdaptiveBadge>
    with AdaptiveElementMixin, AdaptiveVisibilityMixin {
  late String? text;
  late String? iconUrl;
  late String style;
  late String appearance;
  late String size;
  late String? tooltip;
  late String iconAlignment;

  @override
  void initState() {
    super.initState();
    text = adaptiveMap['text'] as String?;
    iconUrl = adaptiveMap['iconUrl'] as String?;
    style = adaptiveMap['style']?.toString().toLowerCase() ?? 'default';
    appearance =
        adaptiveMap['appearance']?.toString().toLowerCase() ?? 'filled';
    size = adaptiveMap['size']?.toString().toLowerCase() ?? 'medium';
    tooltip = adaptiveMap['tooltip'] as String?;
    iconAlignment =
        adaptiveMap['iconAlignment']?.toString().toLowerCase() ?? 'left';
  }

  @override
  Widget build(BuildContext context) {
    final resolver = InheritedReferenceResolver.of(context).resolver;
    final Color backgroundColor =
        resolveBadgeBackgroundColor(
          badgeStyles: resolver.getBadgeStylesConfig(),
          colorStyle: style,
          appearance: appearance,
        ) ??
        Colors.grey;
    final Color textColor =
        resolveBadgeForegroundColor(
          badgeStyles: resolver.getBadgeStylesConfig(),
          colorStyle: style,
          appearance: appearance,
        ) ??
        Colors.black;

    // Resolve subtle vs non-subtle via HostConfig if possible,
    // but for now hardcode based on "style"

    Widget? iconWidget;
    if (iconUrl != null) {
      iconWidget = AdaptiveImageUtils.getImage(iconUrl!, height: 16, width: 16);
    }

    final List<Widget> children = [];
    if (iconAlignment == 'left' && iconWidget != null) {
      children.add(iconWidget);
      if (text != null) children.add(const SizedBox(width: 4));
    }

    if (text != null) {
      children.add(
        Text(
          text!,
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

  /// Resolves the foreground color for a Badge
  Color? resolveBadgeForegroundColor({
    BadgeStylesConfig? badgeStyles,
    String? colorStyle,
    String? appearance,
    bool? isSubtle,
  }) {
    final myBadgeStyles =
        badgeStyles ?? FallbackConfigs.fallbackBadgeStylesConfig;

    final String myColorStyle = colorStyle ?? 'default';
    final BadgeStyleConfig badgeStyle = (appearance?.toLowerCase() == 'tint')
        ? myBadgeStyles.tint
        : myBadgeStyles.filled;
    final FontColorConfig colorConfig = badgeStyle.foregroundColors
        .fontColorConfig(myColorStyle);
    final Color foregroundColor = (isSubtle ?? false)
        ? colorConfig.subtleColor
        : colorConfig.defaultColor;

    return foregroundColor;
  }

  /// Resolves the background color for a Badge
  Color? resolveBadgeBackgroundColor({
    BadgeStylesConfig? badgeStyles,
    String? colorStyle,
    String? appearance,
  }) {
    final myBadgeStyles =
        badgeStyles ?? FallbackConfigs.fallbackBadgeStylesConfig;

    final String myColorStyle = colorStyle ?? 'default';
    final BadgeStyleConfig badgeStyle = (appearance?.toLowerCase() == 'tint')
        ? myBadgeStyles.tint
        : myBadgeStyles.filled;
    final FontColorConfig colorConfig = badgeStyle.backgroundColors
        .fontColorConfig(myColorStyle);
    final Color backgroundColor = colorConfig.defaultColor;

    return backgroundColor;
  }
}
