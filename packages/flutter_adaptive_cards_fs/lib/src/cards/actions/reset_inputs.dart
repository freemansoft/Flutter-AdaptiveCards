import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/action/generic_action.dart';
import 'package:flutter_adaptive_cards_fs/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards_fs/src/cards/actions/icon_button.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';

///
/// https://adaptivecards.io/explorer/Action.ResetInputs.html
///
/// Renders `Action.ResetInputs` as an elevated button and clears targeted
/// inputs via [GenericActionResetInputs].
class AdaptiveActionResetInputs extends StatefulWidget
    with AdaptiveElementWidgetMixin {
  /// Creates an `Action.ResetInputs` widget from [adaptiveMap].
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

/// State for [AdaptiveActionResetInputs].
class AdaptiveActionResetInputsState extends State<AdaptiveActionResetInputs>
    with AdaptiveActionMixin, AdaptiveElementMixin, ProviderScopeMixin {
  /// Resolved `Action.ResetInputs` handler from the action type registry.
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
        // [GenericActionResetInputs]
        action.tap(
          context: context,
          rawAdaptiveCardState: rawRootCardWidgetState,
          adaptiveMap: adaptiveMap,
        );
      },
    );
  }
}
