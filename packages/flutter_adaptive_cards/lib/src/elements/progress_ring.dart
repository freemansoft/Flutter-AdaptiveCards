import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards/src/additional.dart';
import 'package:flutter_adaptive_cards/src/flutter_raw_adaptive_card.dart';
import 'package:flutter_adaptive_cards/src/hostconfig/progress_config.dart';
import 'package:flutter_adaptive_cards/src/inherited_reference_resolver.dart';

class AdaptiveProgressRing extends StatefulWidget
    with AdaptiveElementWidgetMixin {
  AdaptiveProgressRing({
    super.key,
    required this.adaptiveMap,
    required this.widgetState,
  });

  @override
  final Map<String, dynamic> adaptiveMap;
  @override
  final RawAdaptiveCardState widgetState;

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
    if (adaptiveMap.containsKey('value')) {
      final val = adaptiveMap['value'];
      if (val != null) {
        percent = (val as num).toDouble() / 100.0;
        if (percent! < 0) percent = 0;
        if (percent! > 1) percent = 1;
      }
    } else {
      percent = null;
    }

    color = adaptiveMap['color'] as String?;
    size = (adaptiveMap['size'] as String? ?? 'medium').toLowerCase();

    label = adaptiveMap['label'] as String?;
    labelPosition = (adaptiveMap['labelPosition'] as String? ?? 'Above')
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
    final colorString = adaptiveMap['color'] as String?;
    progressColor = ProgressColorsConfig.resolveProgressColor(
      config: InheritedReferenceResolver.of(
        context,
      ).resolver.getProgressColorConfig(),
      color: colorString,
    );
    final sizeString = adaptiveMap['size'] as String?;
    sizePx =
        ProgressSizesConfig.resolveProgressSize(
          InheritedReferenceResolver.of(
            context,
          ).resolver.getProgressSizesConfig(),
          sizeString,
        ) ??
        30;
  }

  @override
  Widget build(BuildContext context) {
    // Stroke width - scale slightly?
    double stroke = sizePx / 10.0;
    if (stroke < 2) stroke = 2;

    final Widget ring = SizedBox(
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
      final Widget labelWidget = Text(label!);

      if (labelPosition == 'above') {
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [labelWidget, const SizedBox(height: 4), ring],
        );
      } else if (labelPosition == 'below') {
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [ring, const SizedBox(height: 4), labelWidget],
        );
      } else if (labelPosition == 'left') {
        content = Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [labelWidget, const SizedBox(width: 8), ring],
        );
      } else if (labelPosition == 'right') {
        content = Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [ring, const SizedBox(width: 8), labelWidget],
        );
      } else {
        // Default above
        content = Column(
          children: [labelWidget, ring],
        );
      }
    }

    return SeparatorElement(
      adaptiveMap: adaptiveMap,
      widgetState: widgetState,
      child: content,
    );
  }
}
