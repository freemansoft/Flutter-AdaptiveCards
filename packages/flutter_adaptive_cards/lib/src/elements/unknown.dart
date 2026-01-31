import 'package:flutter/material.dart';

import 'package:flutter_adaptive_cards/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards/src/utils/utils.dart';

/// Element for an unknown type
///
/// This Element is returned when an unknown element type is encountered.
///
/// When in production, these are blank elements which don't render anything.
///
/// In debug mode these contain an error message describing the problem.
class AdaptiveUnknown extends StatefulWidget with AdaptiveElementWidgetMixin {
  AdaptiveUnknown({
    required this.adaptiveMap,
    required this.type,
  }) : super(key: generateAdaptiveWidgetKey(adaptiveMap)) {
    id = loadId(adaptiveMap);
  }

  @override
  final Map<String, dynamic> adaptiveMap;

  @override
  late final String id;

  final String type;

  @override
  AdaptiveUnknownState createState() => AdaptiveUnknownState();
}

class AdaptiveUnknownState extends State<AdaptiveUnknown>
    with AdaptiveElementMixin {
  @override
  Widget build(BuildContext context) {
    Widget result = const SizedBox();

    // Only do this in debug mode
    assert(() {
      result = ErrorWidget(
        'Type ${widget.type} not found. \n\n'
        'Because of this, a portion of the tree was dropped: \n'
        '$adaptiveMap',
      );

      return true;
    }());

    return result;
  }
}
