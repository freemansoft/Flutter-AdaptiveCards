import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/action/generic_action.dart';
import 'package:flutter_adaptive_cards_fs/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards_fs/src/cards/actions/icon_button.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';

///
/// **Deprecated/legacy:** `Action.Http` was the original Adaptive Cards HTTP
/// action model (schema v1.0), superseded by `Action.Execute` (Universal Action
/// Model, schema v1.4). It is still used by Outlook Actionable Messages
/// (<https://learn.microsoft.com/en-us/outlook/actionable-messages/adaptive-card>).
///
/// Renders `Action.Http` as a button and forwards an `HttpActionInvoke` to the
/// host via [GenericHttpAction].
class AdaptiveActionHttp extends StatefulWidget
    with AdaptiveElementWidgetMixin {
  /// Creates an `Action.Http` widget from [adaptiveMap].
  AdaptiveActionHttp({
    required this.adaptiveMap,
  }) : super(key: generateAdaptiveWidgetKey(adaptiveMap)) {
    id = loadId(adaptiveMap);
  }

  @override
  final Map<String, dynamic> adaptiveMap;

  @override
  late final String id;

  @override
  AdaptiveActionHttpState createState() => AdaptiveActionHttpState();
}

/// State for [AdaptiveActionHttp].
class AdaptiveActionHttpState extends State<AdaptiveActionHttp>
    with AdaptiveActionMixin, AdaptiveElementMixin, ProviderScopeMixin {
  /// Resolved `Action.Http` handler from the action type registry.
  late GenericHttpAction action;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    action =
        actionTypeRegistry.getActionForType(
              map: adaptiveMap,
            )!
            as GenericHttpAction;
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
