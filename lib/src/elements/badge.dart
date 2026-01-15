import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards/src/additional.dart';

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
    text = widget.adaptiveMap['text'];
    iconUrl = widget.adaptiveMap['iconUrl'];
    style = widget.adaptiveMap['style']?.toLowerCase() ?? 'default';
    size = widget.adaptiveMap['size']?.toLowerCase() ?? 'medium';
    tooltip = widget.adaptiveMap['tooltip'];
    iconAlignment =
        widget.adaptiveMap['iconAlignment']?.toLowerCase() ?? 'left';
  }

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;

    // TODO: move these colors to a theme resolver
    switch (style) {
      case 'accent':
        backgroundColor = Colors.blue; // Example color
        textColor = Colors.white;
        break;
      case 'good':
        backgroundColor = Colors.green;
        textColor = Colors.white;
        break;
      case 'warning':
        backgroundColor = Colors.orange;
        textColor = Colors.black;
        break;
      case 'attention':
        backgroundColor = Colors.red;
        textColor = Colors.white;
        break;
      case 'default':
      default:
        backgroundColor = Colors.grey; // Example color
        textColor = Colors.black;
        break;
    }

    // Resolve subtle vs non-subtle via HostConfig if possible,
    // but for now hardcode based on "style"

    Widget? iconWidget;
    if (iconUrl != null) {
      iconWidget = Image.network(iconUrl!, height: 16, width: 16);
    }

    List<Widget> children = [];
    if (iconAlignment == 'left' && iconWidget != null) {
      children.add(iconWidget);
      if (text != null) children.add(SizedBox(width: 4));
    }

    if (text != null) {
      children.add(
        Text(
          text!,
          style: TextStyle(
            color: textColor,
            fontSize: size == 'large' ? 14 : 12,
          ),
        ),
      );
    }

    if (iconAlignment == 'right' && iconWidget != null) {
      if (text != null) children.add(SizedBox(width: 4));
      children.add(iconWidget);
    }

    Widget badge = Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12), // Pill shape
      ),
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );

    if (tooltip != null) {
      badge = Tooltip(message: tooltip!, child: badge);
    }

    return SeparatorElement(
      adaptiveMap: widget.adaptiveMap,
      child: badge,
    );
  }
}
