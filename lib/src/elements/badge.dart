import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards/src/additional.dart';
import 'package:flutter_adaptive_cards/src/inherited_reference_resolver.dart';

class AdaptiveBadge extends StatefulWidget with AdaptiveElementWidgetMixin {
  AdaptiveBadge({super.key, required this.adaptiveMap});

  @override
  final Map<String, dynamic> adaptiveMap;

  @override
  AdaptiveBadgeState createState() => AdaptiveBadgeState();
}

class AdaptiveBadgeState extends State<AdaptiveBadge>
    with AdaptiveElementMixin {
  late String? text;
  late String? iconUrl;
  late String style;
  late String size;
  late String? tooltip;
  late String iconAlignment;

  @override
  void initState() {
    super.initState();
    text = widget.adaptiveMap['text'] as String?;
    iconUrl = widget.adaptiveMap['iconUrl'] as String?;
    style = widget.adaptiveMap['style']?.toString().toLowerCase() ?? 'default';
    size = widget.adaptiveMap['size']?.toString().toLowerCase() ?? 'medium';
    tooltip = widget.adaptiveMap['tooltip'] as String?;
    iconAlignment =
        widget.adaptiveMap['iconAlignment']?.toString().toLowerCase() ?? 'left';
  }

  @override
  Widget build(BuildContext context) {
    final resolver = InheritedReferenceResolver.of(context).resolver;
    final Color backgroundColor = resolver.resolveBadgeBackgroundColor(style);
    final Color textColor = resolver.resolveBadgeForegroundColor(style);

    // Resolve subtle vs non-subtle via HostConfig if possible,
    // but for now hardcode based on "style"

    Widget? iconWidget;
    if (iconUrl != null) {
      iconWidget = Image.network(iconUrl!, height: 16, width: 16);
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

    return SeparatorElement(
      adaptiveMap: widget.adaptiveMap,
      child: badge,
    );
  }
}
