import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/action/generic_action.dart';
import 'package:flutter_adaptive_cards_fs/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards_fs/src/cards/actions/icon_button.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';

///
/// https://adaptivecards.io/explorer/Action.Submit.html
/// https://learn.microsoft.com/en-us/adaptive-cards/schema-explorer/action-submit
///
/// Renders `Action.Submit` as an elevated button and collects input values for
/// the host via [GenericSubmitAction].
class AdaptiveActionSubmit extends StatefulWidget
    with AdaptiveElementWidgetMixin {
  /// Creates an `Action.Submit` widget from [adaptiveMap].
  AdaptiveActionSubmit({
    required this.adaptiveMap,
  }) : super(key: generateAdaptiveWidgetKey(adaptiveMap)) {
    id = loadId(adaptiveMap);
  }

  @override
  final Map<String, dynamic> adaptiveMap;

  @override
  late final String id;

  @override
  AdaptiveActionSubmitState createState() => AdaptiveActionSubmitState();
}

/// State for [AdaptiveActionSubmit].
class AdaptiveActionSubmitState extends State<AdaptiveActionSubmit>
    with AdaptiveActionMixin, AdaptiveElementMixin, ProviderScopeMixin {
  /// Resolved `Action.Submit` handler from the action type registry.
  late GenericSubmitAction action;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    action =
        actionTypeRegistry.getActionForType(
              map: adaptiveMap,
            )!
            as GenericSubmitAction;
  }

  @override
  Widget build(BuildContext context) {
    return IconButtonAction(
      adaptiveMap: adaptiveMap,
      onTapped: (BuildContext context) {
        // [GenericSubmitAction]
        action.tap(
          context: context,
          rawAdaptiveCardState: rawRootCardWidgetState,
          adaptiveMap: adaptiveMap,
        );
      },
    );
  }
}
