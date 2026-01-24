import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards/src/elements/actions/icon_button.dart';
import 'package:flutter_adaptive_cards/src/generic_action.dart';

class AdaptiveActionResetInputs extends StatefulWidget
    with AdaptiveElementWidgetMixin {
  AdaptiveActionResetInputs({super.key, required this.adaptiveMap});

  @override
  final Map<String, dynamic> adaptiveMap;

  @override
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
        widgetState.cardRegistry.getGenericAction(
              adaptiveMap,
              widgetState,
            )!
            as GenericActionResetInputs;
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
