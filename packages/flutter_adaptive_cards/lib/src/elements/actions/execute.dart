import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/src/actions/generic_action.dart';
import 'package:flutter_adaptive_cards/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards/src/elements/actions/icon_button.dart';
import 'package:flutter_adaptive_cards/src/utils/utils.dart';

///
/// https://adaptivecards.io/explorer/Action.Execute.html
///
class AdaptiveActionExecute extends StatefulWidget
    with AdaptiveElementWidgetMixin {
  AdaptiveActionExecute({
    required this.adaptiveMap,
  }) : super(key: generateAdaptiveWidgetKey(adaptiveMap)) {
    id = loadId(adaptiveMap);
  }

  @override
  final Map<String, dynamic> adaptiveMap;

  @override
  late final String id;

  @override
  AdaptiveActionExecuteState createState() => AdaptiveActionExecuteState();
}

class AdaptiveActionExecuteState extends State<AdaptiveActionExecute>
    with AdaptiveActionMixin, AdaptiveElementMixin {
  late GenericExecuteAction action;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    action =
        actionTypeRegistry.getActionForType(
              map: adaptiveMap,
            )!
            as GenericExecuteAction;
  }

  @override
  Widget build(BuildContext context) {
    return IconButtonAction(
      adaptiveMap: adaptiveMap,
      onTapped: (BuildContext context) {
        action.tap(
          context: context,
          rawAdaptiveCardState: rawRootCardWidgetState,
          adaptiveMap: adaptiveMap,
        );
      },
    );
  }
}
