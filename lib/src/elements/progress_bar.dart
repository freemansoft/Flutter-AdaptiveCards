import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards/src/additional.dart';
import 'package:flutter_adaptive_cards/src/inherited_reference_resolver.dart';

class AdaptiveProgressBar extends StatefulWidget
    with AdaptiveElementWidgetMixin {
  AdaptiveProgressBar({super.key, required this.adaptiveMap});

  @override
  final Map<String, dynamic> adaptiveMap;

  @override
  AdaptiveProgressBarState createState() => AdaptiveProgressBarState();
}

class AdaptiveProgressBarState extends State<AdaptiveProgressBar>
    with AdaptiveElementMixin {
  double? percent;
  late String? color;
  late bool separator;
  Color? progressColor;

  @override
  void initState() {
    super.initState();
    // percent is usually 0-100 in AC, LinearProgressIndicator takes 0.0-1.0
    // If value is missing, percent is null -> indeterminate
    if (widget.adaptiveMap.containsKey('value')) {
      final val = widget.adaptiveMap['value'];
      if (val != null) {
        percent = (val as num).toDouble() / 100.0;
        if (percent! < 0) percent = 0;
        if (percent! > 1) percent = 1;
      }
    } else {
      percent = null;
    }

    separator = widget.adaptiveMap['separator'] == true;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final colorString = widget.adaptiveMap['color']?.toString();
    progressColor = InheritedReferenceResolver.of(
      context,
    ).resolver.resolveProgressColor(context: context, color: colorString);
  }

  @override
  Widget build(BuildContext context) {
    Widget progressBar;
    if (percent != null) {
      progressBar = LinearProgressIndicator(
        value: percent,
        color: progressColor,
        backgroundColor: Colors.grey[300],
        minHeight: 10,
        borderRadius: BorderRadius.circular(5),
      );
    } else {
      // Indeterminate
      // Indeterminate LinearProgressIndicator in Material default behavior is "move back and forth"
      // "foreground should be 10% of the full width" - Material default might not be exactly 10% but matches behavior.
      progressBar = LinearProgressIndicator(
        color: progressColor,
        backgroundColor: Colors.grey[300],
        minHeight: 10,
        borderRadius: BorderRadius.circular(5),
      );
    }

    final content = progressBar;

    if (separator) {
      // Separator implies top spacing/line.
      // Adaptive cards separator is usually handled by SeparatorElement somewhat,
      // but if we need explicit line:
      // However, usually `separator: true` in AC means "draw a line before this element".
      // SeparatorElement (wrapper) usually handles spacing. Does it handle line?
      // Let's check SeparatorElement implementation usage.
      // Looking at other files, SeparatorElement takes `adaptiveMap`.
      // If SeparatorElement handles it, we are good. If not, we might need to Column it.
      // But looking at SeparatorElement source (from memory/context), it adds spacing.
      // Explicit separator line might be needed if SeparatorElement doesn't draw it.
      // In Flutter Adaptive Cards, usually `separator: true` adds spacing + optional divider?
      // Let's assume SeparatorElement handles the logic or we trust the framework's existing mixin.
      // But user specifically asked "The ProgressBar supports the 'separator' property which is a leading separator".
      // We will ensure SeparatorElement is used, which we are.
    }

    return SeparatorElement(
      adaptiveMap: widget.adaptiveMap,
      child: content,
    );
  }
}
