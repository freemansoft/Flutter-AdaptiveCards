import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards_fs/src/additional.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Renders the Adaptive Cards **ProgressBar** element.
///
/// See https://adaptivecards.io/explorer/ProgressBar.html
class AdaptiveProgressBar extends ConsumerStatefulWidget
    with AdaptiveElementWidgetMixin {
  /// Creates a progress bar from [adaptiveMap] JSON.
  AdaptiveProgressBar({
    required this.adaptiveMap,
  }) : super(key: generateAdaptiveWidgetKey(adaptiveMap)) {
    id = loadId(adaptiveMap);
  }
  @override
  final Map<String, dynamic> adaptiveMap;

  @override
  late final String id;

  @override
  AdaptiveProgressBarState createState() => AdaptiveProgressBarState();
}

/// State for [AdaptiveProgressBar]; maps `value` to a linear indicator.
class AdaptiveProgressBarState extends ConsumerState<AdaptiveProgressBar>
    with AdaptiveElementMixin, AdaptiveVisibilityMixin, ProviderScopeMixin {
  /// Completion fraction 0.0–1.0 from `value`, or null when indeterminate.
  double? percent;

  /// Color token from `color` (resolved via HostConfig).
  late String? color;

  /// Whether to show a separator below the bar.
  late bool separator;

  /// Resolved foreground color for the progress indicator.
  Color? progressColor;

  @override
  void initState() {
    super.initState();
    // percent is usually 0-100 in AC, LinearProgressIndicator takes 0.0-1.0
    // If value is missing, percent is null -> indeterminate
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

    separator = adaptiveMap['separator'] == true;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final colorString = adaptiveMap['color']?.toString();
    progressColor = styleResolver.resolveProgressColor(colorString);
  }

  @override
  Widget build(BuildContext context) {
    Widget progressBar;
    if (percent != null) {
      progressBar = LinearProgressIndicator(
        value: percent,
        color: progressColor,
        backgroundColor: styleResolver.resolveProgressBackgroundColor(),
        minHeight: 10,
        borderRadius: BorderRadius.circular(5),
      );
    } else {
      // Indeterminate
      // Indeterminate LinearProgressIndicator in Material default behavior is "move back and forth"
      // "foreground should be 10% of the full width" - Material default might not be exactly 10% but matches behavior.
      progressBar = LinearProgressIndicator(
        color: progressColor,
        backgroundColor: styleResolver.resolveProgressBackgroundColor(),
        minHeight: 10,
        borderRadius: BorderRadius.circular(5),
      );
    }

    final content = progressBar;

    return Visibility(
      visible: isVisible,
      child: SeparatorElement(
        adaptiveMap: adaptiveMap,
        child: content,
      ),
    );
  }
}
