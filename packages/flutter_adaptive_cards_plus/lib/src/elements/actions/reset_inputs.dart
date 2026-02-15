import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_plus/src/actions/generic_action.dart';
import 'package:flutter_adaptive_cards_plus/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards_plus/src/elements/actions/icon_button.dart';
import 'package:flutter_adaptive_cards_plus/src/utils/utils.dart';

class AdaptiveActionResetInputs extends StatefulWidget
    with AdaptiveElementWidgetMixin {
  AdaptiveActionResetInputs({
    required this.adaptiveMap,
  }) : super(key: generateAdaptiveWidgetKey(adaptiveMap)) {
    id = loadId(adaptiveMap);
  }

  @override
  final Map<String, dynamic> adaptiveMap;

  @override
  late final String id;

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
        actionTypeRegistry.getActionForType(
              map: adaptiveMap,
            )!
            as GenericActionResetInputs;
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
