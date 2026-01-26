import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards/src/elements/actions/icon_button.dart';
import 'package:flutter_adaptive_cards/src/flutter_raw_adaptive_card.dart';
import 'package:flutter_adaptive_cards/src/generic_action.dart';

class AdaptiveActionResetInputs extends StatefulWidget
    with AdaptiveElementWidgetMixin {
  AdaptiveActionResetInputs({
    super.key,
    required this.adaptiveMap,
    required this.widgetState,
  }) {
    id = loadId(adaptiveMap);
  }

  @override
  final Map<String, dynamic> adaptiveMap;

  @override
  final RawAdaptiveCardState widgetState;

  @override
  late final String id;

  AdaptiveActionResetInputsState createState() =>
      AdaptiveActionResetInputsState();
}

class AdaptiveActionResetInputsState extends State<AdaptiveActionResetInputs>
    with AdaptiveActionMixin, AdaptiveElementMixin {
  late GenericActionResetInputs action;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    action =
        widgetState.cardTypeRegistry.getGenericAction(
              map: adaptiveMap,
              state: widgetState,
            )!
            as GenericActionResetInputs;
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
