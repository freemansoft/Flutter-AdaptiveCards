import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards/src/elements/actions/icon_button.dart';
import 'package:flutter_adaptive_cards/src/flutter_raw_adaptive_card.dart';
import 'package:flutter_adaptive_cards/src/generic_action.dart';

///
/// https://adaptivecards.io/explorer/Action.Execute.html
///
class AdaptiveActionExecute extends StatefulWidget
    with AdaptiveElementWidgetMixin {
  AdaptiveActionExecute({
    super.key,
    required this.adaptiveMap,
    required this.widgetState,
  });

  @override
  final Map<String, dynamic> adaptiveMap;

  @override
  final RawAdaptiveCardState widgetState;

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
        widgetState.cardRegistry.getGenericAction(
              map: adaptiveMap,
              state: widgetState,
            )!
            as GenericExecuteAction;
  }

  @override
  Widget build(BuildContext context) {
    return IconButtonAction(
      adaptiveMap: adaptiveMap,
      onTapped: onTapped,
      widgetState: widgetState,
    );
  }

  @override
  void onTapped() {
    action.tap();
  }
}
