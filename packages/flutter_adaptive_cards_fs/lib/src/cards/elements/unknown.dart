import 'package:flutter/material.dart';

import 'package:flutter_adaptive_cards_fs/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';
import 'package:flutter_adaptive_cards_fs/src/widgets/adaptive_error_placeholder.dart';

/// Element for an unknown type
///
/// This Element is returned when an unknown element type is encountered,
/// rendered as an [AdaptiveErrorPlaceholder] describing the problem.
class AdaptiveUnknown extends StatefulWidget with AdaptiveElementWidgetMixin {
  /// Creates a placeholder for an unrecognized element [type].
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

  /// The unrecognized `type` string from card JSON.
  final String type;

  @override
  AdaptiveUnknownState createState() => AdaptiveUnknownState();
}

/// State for [AdaptiveUnknown]; shows an [AdaptiveErrorPlaceholder].
class AdaptiveUnknownState extends State<AdaptiveUnknown>
    with AdaptiveElementMixin, ProviderScopeMixin {
  @override
  Widget build(BuildContext context) {
    final message =
        'Type ${widget.type} not found. \n\n'
        'Because of this, a portion of the tree was dropped: \n'
        '$adaptiveMap';
    debugPrint(message);
    return AdaptiveErrorPlaceholder(message: message);
  }
}
