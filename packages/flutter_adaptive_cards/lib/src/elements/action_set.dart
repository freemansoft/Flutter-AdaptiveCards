import 'package:flutter/material.dart';

import 'package:flutter_adaptive_cards/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards/src/additional.dart';
import 'package:flutter_adaptive_cards/src/flutter_raw_adaptive_card.dart';
import 'package:flutter_adaptive_cards/src/inherited_reference_resolver.dart';
import 'package:flutter_adaptive_cards/src/utils/utils.dart';

///
/// https://adaptivecards.io/explorer/ActionSet.html
///
/// This class is described as a _Container_ in the docs but is located in elements for some reason
///
class ActionSet extends StatefulWidget with AdaptiveElementWidgetMixin {
  ActionSet({
    required this.adaptiveMap,
    required this.widgetState,
  }) : super(key: generateWidgetKey(adaptiveMap)) {
    id = loadId(adaptiveMap);
  }

  @override
  final Map<String, dynamic> adaptiveMap;

  @override
  final RawAdaptiveCardState widgetState;

  @override
  late final String id;

  @override
  ActionSetState createState() => ActionSetState();
}

class ActionSetState extends State<ActionSet> with AdaptiveElementMixin {
  List<Widget> activeActions = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final resolver = InheritedReferenceResolver.of(context).resolver;
    final actionsConfig = resolver.getActionsConfig();

    activeActions.clear();
    final List actionMaps = adaptiveMap['actions'] as List<dynamic>? ?? [];

    // Limit actions by maxActions
    final int maxActions = actionsConfig?.maxActions ?? 10;
    final List limitedActionMaps = actionMaps.take(maxActions).toList();

    activeActions.addAll(
      List<Map<String, dynamic>>.from(limitedActionMaps).map(
        (adaptiveMap) => widgetState.cardTypeRegistry.getAction(
          map: adaptiveMap,
          state: widgetState,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolver = InheritedReferenceResolver.of(context).resolver;
    final actionsConfig = resolver.getActionsConfig();

    return SeparatorElement(
      adaptiveMap: adaptiveMap,
      widgetState: widgetState,
      child: Wrap(
        spacing: actionsConfig?.buttonSpacing.toDouble() ?? 10,
        runSpacing: actionsConfig?.buttonSpacing.toDouble() ?? 10,
        direction: actionsConfig?.actionsOrientation.toLowerCase() == 'vertical'
            ? Axis.vertical
            : Axis.horizontal,
        alignment: _getWrapAlignment(actionsConfig?.actionAlignment ?? 'left'),
        children: activeActions,
      ),
    );
  }

  WrapAlignment _getWrapAlignment(String alignment) {
    switch (alignment.toLowerCase()) {
      case 'left':
        return WrapAlignment.start;
      case 'center':
        return WrapAlignment.center;
      case 'right':
        return WrapAlignment.end;
      case 'stretch':
      default:
        // Wrap doesn't have a direct "stretch" that behaves like Flex's crossAxisAlignment.stretch
        // but for actions it usually means spread or start depending on orientation.
        return WrapAlignment.start;
    }
  }
}
