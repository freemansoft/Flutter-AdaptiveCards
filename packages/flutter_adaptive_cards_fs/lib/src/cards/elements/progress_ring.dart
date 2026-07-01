import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards_fs/src/additional.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/progress_config.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Renders the Adaptive Cards **ProgressRing** element.
///
/// See https://adaptivecards.io/explorer/ProgressRing.html
class AdaptiveProgressRing extends ConsumerStatefulWidget
    with AdaptiveElementWidgetMixin {
  /// Creates a progress ring from [adaptiveMap] JSON.
  AdaptiveProgressRing({
    required this.adaptiveMap,
  }) : super(key: generateAdaptiveWidgetKey(adaptiveMap)) {
    id = loadId(adaptiveMap);
  }

  @override
  final Map<String, dynamic> adaptiveMap;

  @override
  late final String id;

  @override
  AdaptiveProgressRingState createState() => AdaptiveProgressRingState();
}

/// State for [AdaptiveProgressRing]; lays out ring and optional label.
class AdaptiveProgressRingState extends ConsumerState<AdaptiveProgressRing>
    with AdaptiveElementMixin, AdaptiveVisibilityMixin, ProviderScopeMixin {
  /// Completion fraction 0.0–1.0 from `value`, or null when indeterminate.
  double? percent;

  /// Color token from `color`.
  late String? color;

  /// Size token: `small`, `medium`, or `large`.
  late String size;

  /// Optional caption from `label`.
  String? label;

  /// Label placement: `above`, `below`, `left`, or `right`.
  String? labelPosition;

  /// Resolved foreground color for the ring stroke.
  Color? progressColor;

  /// Ring diameter in logical pixels from HostConfig.
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
    // "Above" is default? JSON says "Above (default)" in label text, but let's
    // assume Above. Spec says default is likely Top/Above? JSON used "Before",
    // "After" which map to Left/Right? User request: "Above", "Below", "left"
    // "right".
    if (labelPosition == 'before') labelPosition = 'left';
    if (labelPosition == 'after') labelPosition = 'right';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final colorString = adaptiveMap['color'] as String?;
    progressColor = styleResolver.resolveProgressColor(colorString);
    final sizeString = adaptiveMap['size'] as String?;
    sizePx =
        ProgressSizesConfig.resolveProgressSize(
          styleResolver.getProgressSizesConfig(),
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
        backgroundColor: styleResolver.resolveProgressBackgroundColor(),
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

    return Visibility(
      visible: isVisible,
      child: SeparatorElement(
        adaptiveMap: adaptiveMap,
        child: content,
      ),
    );
  }
}
