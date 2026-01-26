import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards/src/elements/actions/icon_button.dart';
import 'package:flutter_adaptive_cards/src/flutter_raw_adaptive_card.dart';
import 'package:flutter_adaptive_cards/src/generic_action.dart';
import 'package:flutter_adaptive_cards/src/utils/utils.dart';

///
/// https://adaptivecards.io/explorer/Action.Submit.html
///
class AdaptiveActionSubmit extends StatefulWidget
    with AdaptiveElementWidgetMixin {
  AdaptiveActionSubmit({
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
  AdaptiveActionSubmitState createState() => AdaptiveActionSubmitState();
}

class AdaptiveActionSubmitState extends State<AdaptiveActionSubmit>
    with AdaptiveActionMixin, AdaptiveElementMixin {
  late GenericSubmitAction action;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    action =
        widgetState.cardTypeRegistry.getGenericAction(
              map: adaptiveMap,
              state: widgetState,
            )!
            as GenericSubmitAction;
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
