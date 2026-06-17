import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/action/generic_action.dart';
import 'package:flutter_adaptive_cards_fs/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards_fs/src/cards/actions/icon_button.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';

export 'package:flutter_adaptive_cards_fs/src/cards/actions/popover_container.dart'
    show AdaptivePopoverContainer;

///
/// https://adaptivecards.io/explorer/Action.Popover.html
///
/// Renders `Action.Popover` as an elevated button that opens the nested `card`
/// payload in a dialog.
class AdaptiveActionPopover extends StatefulWidget
    with AdaptiveElementWidgetMixin {
  /// Creates an `Action.Popover` widget from [adaptiveMap].
  AdaptiveActionPopover({
    required this.adaptiveMap,
  }) : super(key: generateAdaptiveWidgetKey(adaptiveMap)) {
    id = loadId(adaptiveMap);
  }

  @override
  final Map<String, dynamic> adaptiveMap;

  @override
  late final String id;

  @override
  AdaptiveActionPopoverState createState() => AdaptiveActionPopoverState();
}

/// State for [AdaptiveActionPopover].
class AdaptiveActionPopoverState extends State<AdaptiveActionPopover>
    with AdaptiveActionMixin, AdaptiveElementMixin, ProviderScopeMixin {
  /// Resolved `Action.Popover` handler from the action type registry.
  late GenericPopoverAction action;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    action =
        actionTypeRegistry.getActionForType(map: adaptiveMap)!
            as GenericPopoverAction;
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
