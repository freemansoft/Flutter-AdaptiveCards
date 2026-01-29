import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards/src/additional.dart';
import 'package:flutter_adaptive_cards/src/hostconfig/progress_config.dart';
import 'package:flutter_adaptive_cards/src/inherited_reference_resolver.dart';
import 'package:flutter_adaptive_cards/src/utils/utils.dart';

class AdaptiveProgressBar extends StatefulWidget
    with AdaptiveElementWidgetMixin {
  AdaptiveProgressBar({
    required this.adaptiveMap,
  }) : super(key: generateWidgetKey(adaptiveMap)) {
    id = loadId(adaptiveMap);
  }
  @override
  final Map<String, dynamic> adaptiveMap;

  @override
  late final String id;

  @override
  AdaptiveProgressBarState createState() => AdaptiveProgressBarState();
}

class AdaptiveProgressBarState extends State<AdaptiveProgressBar>
    with AdaptiveElementMixin, AdaptiveVisibilityMixin {
  double? percent;
  late String? color;
  late bool separator;
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
    progressColor = ProgressColorsConfig.resolveProgressColor(
      config: InheritedReferenceResolver.of(
        context,
      ).resolver.getProgressColorConfig(),
      color: colorString,
    );
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

    return Visibility(
      visible: isVisible,
      child: SeparatorElement(
        adaptiveMap: adaptiveMap,
        child: content,
      ),
    );
  }
}
