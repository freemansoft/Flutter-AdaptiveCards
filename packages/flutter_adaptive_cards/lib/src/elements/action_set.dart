import 'package:flutter/material.dart';

import 'package:flutter_adaptive_cards/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards/src/elements/actions/execute.dart';
import 'package:flutter_adaptive_cards/src/elements/actions/open_url.dart';
import 'package:flutter_adaptive_cards/src/elements/actions/show_card.dart';
import 'package:flutter_adaptive_cards/src/elements/actions/submit.dart';
import 'package:flutter_adaptive_cards/src/elements/unknown.dart';
import 'package:flutter_adaptive_cards/src/flutter_raw_adaptive_card.dart';
import 'package:flutter_adaptive_cards/src/inherited_reference_resolver.dart';

///
/// https://adaptivecards.io/explorer/ActionSet.html
///
/// This class is described as a _Container_ in the docs but is located in elements for some reason
///
class ActionSet extends StatefulWidget with AdaptiveElementWidgetMixin {
  ActionSet({super.key, required this.adaptiveMap, required this.widgetState});

  @override
  final Map<String, dynamic> adaptiveMap;

  @override
  final RawAdaptiveCardState widgetState;

  @override
  ActionSetState createState() => ActionSetState();
}

class ActionSetState extends State<ActionSet> with AdaptiveElementMixin {
  List<Widget> actions = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final resolver = InheritedReferenceResolver.of(context).resolver;
    final actionsConfig = resolver.getActionsConfig();

    actions.clear();
    final List actionMaps = adaptiveMap['actions'] as List<dynamic>? ?? [];

    // Limit actions by maxActions
    final int maxActions = actionsConfig?.maxActions ?? 10;
    final List limitedActionMaps = actionMaps.take(maxActions).toList();

    for (final action in limitedActionMaps) {
      actions.add(_getAction(action));
    }
  }

  @override
  Widget build(BuildContext context) {
    final resolver = InheritedReferenceResolver.of(context).resolver;
    final actionsConfig = resolver.getActionsConfig();

    return Wrap(
      spacing: actionsConfig?.buttonSpacing.toDouble() ?? 10,
      runSpacing: actionsConfig?.buttonSpacing.toDouble() ?? 10,
      direction: actionsConfig?.actionsOrientation.toLowerCase() == 'vertical'
          ? Axis.vertical
          : Axis.horizontal,
      alignment: _getWrapAlignment(actionsConfig?.actionAlignment ?? 'left'),
      children: actions,
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

  Widget _getAction(Map<String, dynamic> map) {
    final String stringType = map['type']?.toString() ?? 'Unknown';

    switch (stringType) {
      case 'Action.ShowCard':
        return AdaptiveActionShowCard(
          adaptiveMap: map,
          widgetState: widgetState,
        );
      case 'Action.ToggleVisibility':
        assert(false, 'Action.ToggleVisibility is not supported');
        return AdaptiveUnknown(
          adaptiveMap: map,
          widgetState: widgetState,
          type: stringType,
        );
      case 'Action.OpenUrl':
        return AdaptiveActionOpenUrl(
          adaptiveMap: map,
          widgetState: widgetState,
        );
      case 'Action.Submit':
        return AdaptiveActionSubmit(adaptiveMap: map, widgetState: widgetState);
      case 'Action.Execute':
        return AdaptiveActionExecute(
          adaptiveMap: map,
          widgetState: widgetState,
        );
      default:
        assert(false, 'No action found with type $stringType');
        return AdaptiveUnknown(
          adaptiveMap: map,
          widgetState: widgetState,
          type: stringType,
        );
    }
  }
}
