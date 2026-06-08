import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/action/generic_action.dart';
import 'package:flutter_adaptive_cards_fs/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards_fs/src/cards/actions/icon_button.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';

///
/// https://adaptivecards.io/explorer/Action.Execute.html
///
/// Renders `Action.Execute` as an elevated button and forwards taps to the host
/// via [GenericExecuteAction].
class AdaptiveActionExecute extends StatefulWidget
    with AdaptiveElementWidgetMixin {
  /// Creates an `Action.Execute` widget from [adaptiveMap].
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

/// State for [AdaptiveActionExecute].
class AdaptiveActionExecuteState extends State<AdaptiveActionExecute>
    with AdaptiveActionMixin, AdaptiveElementMixin, ProviderScopeMixin {
  /// Resolved `Action.Execute` handler from the action type registry.
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
        // [GenericExecuteAction]
        action.tap(
          context: context,
          rawAdaptiveCardState: rawRootCardWidgetState,
          adaptiveMap: adaptiveMap,
        );
      },
    );
  }
}
