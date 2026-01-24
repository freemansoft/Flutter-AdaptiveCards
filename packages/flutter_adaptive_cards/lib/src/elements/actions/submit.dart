import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards/src/elements/actions/icon_button.dart';
import 'package:flutter_adaptive_cards/src/generic_action.dart';

///
/// https://adaptivecards.io/explorer/Action.Submit.html
///
class AdaptiveActionSubmit extends StatefulWidget
    with AdaptiveElementWidgetMixin {
  AdaptiveActionSubmit({super.key, required this.adaptiveMap});

  @override
  final Map<String, dynamic> adaptiveMap;

  @override
  AdaptiveActionSubmitState createState() => AdaptiveActionSubmitState();
}

class AdaptiveActionSubmitState extends State<AdaptiveActionSubmit>
    with AdaptiveActionMixin, AdaptiveElementMixin {
  late GenericSubmitAction action;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    action =
        widgetState.cardRegistry.getGenericAction(
              map: adaptiveMap,
              state: widgetState,
            )!
            as GenericSubmitAction;
  }

  @override
  Widget build(BuildContext context) {
    return IconButtonAction(adaptiveMap: adaptiveMap, onTapped: onTapped);
  }

  @override
  void onTapped() {
    action.tap();
  }
}
