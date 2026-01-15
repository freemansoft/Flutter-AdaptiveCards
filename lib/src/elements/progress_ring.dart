import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards/src/additional.dart';
import 'package:flutter_adaptive_cards/src/inherited_reference_resolver.dart';

class AdaptiveProgressRing extends StatefulWidget
    with AdaptiveElementWidgetMixin {
  AdaptiveProgressRing({super.key, required this.adaptiveMap});

  @override
  final Map<String, dynamic> adaptiveMap;

  @override
  AdaptiveProgressRingState createState() => AdaptiveProgressRingState();
}

class AdaptiveProgressRingState extends State<AdaptiveProgressRing>
    with AdaptiveElementMixin {
  double? percent;
  late String? color;
  late String size;
  String? label;
  String? labelPosition;
  Color? progressColor;
  double sizePx = 30;

  @override
  void initState() {
    super.initState();
    if (widget.adaptiveMap.containsKey('value')) {
      var val = widget.adaptiveMap['value'];
      if (val != null) {
        percent = val.toDouble() / 100.0;
        if (percent! < 0) percent = 0;
        if (percent! > 1) percent = 1;
      }
    } else {
      percent = null;
    }

    color = widget.adaptiveMap['color'];
    size = (widget.adaptiveMap['size'] ?? 'medium').toLowerCase();

    label = widget.adaptiveMap['label'];
    labelPosition = (widget.adaptiveMap['labelPosition'] ?? 'Above')
        .toLowerCase();
    // "Above" is default? JSON says "Above (default)" in label text, but let's assume Above.
    // Spec says default is likely Top/Above?
    // JSON used "Before", "After" which map to Left/Right?
    // User request: "Above", "Below", "left" "right".
    if (labelPosition == 'before') labelPosition = 'left';
    if (labelPosition == 'after') labelPosition = 'right';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    var colorString = widget.adaptiveMap['color']?.toString();
    progressColor = InheritedReferenceResolver.of(
      context,
    ).resolver.resolveProgressColor(context: context, color: colorString);
    var sizeString = widget.adaptiveMap['size']?.toString();
    sizePx = InheritedReferenceResolver.of(
      context,
    ).resolver.resolveProgressSize(sizeString);
  }

  @override
  Widget build(BuildContext context) {
    // Stroke width - scale slightly?
    double stroke = sizePx / 10.0;
    if (stroke < 2) stroke = 2;

    Widget ring = SizedBox(
      width: sizePx,
      height: sizePx,
      child: CircularProgressIndicator(
        value: percent,
        color: progressColor,
        backgroundColor: Colors.grey[300],
        strokeWidth: stroke,
      ),
    );

    Widget content = ring;

    if (label != null && label!.isNotEmpty) {
      Widget labelWidget = Text(label!);

      if (labelPosition == 'above') {
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [labelWidget, SizedBox(height: 4), ring],
        );
      } else if (labelPosition == 'below') {
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [ring, SizedBox(height: 4), labelWidget],
        );
      } else if (labelPosition == 'left') {
        content = Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [labelWidget, SizedBox(width: 8), ring],
        );
      } else if (labelPosition == 'right') {
        content = Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [ring, SizedBox(width: 8), labelWidget],
        );
      } else {
        // Default above
        content = Column(
          children: [labelWidget, ring],
        );
      }
    }

    return SeparatorElement(
      adaptiveMap: widget.adaptiveMap,
      child: content,
    );
  }
}
