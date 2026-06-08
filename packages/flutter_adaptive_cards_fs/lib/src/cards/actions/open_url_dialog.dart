import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/action/generic_action.dart';
import 'package:flutter_adaptive_cards_fs/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards_fs/src/cards/actions/icon_button.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';

///
/// https://adaptivecards.io/explorer/Action.OpenUrlDialog.html
/// https://adaptivecards.microsoft.com/?topic=Action.OpenUrlDialog
///
/// Renders `Action.OpenUrlDialog` as an elevated button. On tap, fetches a
/// card payload from the URL and displays the returned adaptive card in a
/// dialog via [GenericActionOpenUrlDialog].
class AdaptiveActionOpenUrlDialog extends StatefulWidget
    with AdaptiveElementWidgetMixin {
  /// Creates an `Action.OpenUrlDialog` widget from [adaptiveMap].
  AdaptiveActionOpenUrlDialog({
    required this.adaptiveMap,
  }) : super(key: generateAdaptiveWidgetKey(adaptiveMap));

  @override
  final Map<String, dynamic> adaptiveMap;

  @override
  late final String id = loadId(adaptiveMap);

  @override
  AdaptiveActionOpenUrlDialogState createState() =>
      AdaptiveActionOpenUrlDialogState();
}

/// State for [AdaptiveActionOpenUrlDialog].
class AdaptiveActionOpenUrlDialogState
    extends State<AdaptiveActionOpenUrlDialog>
    with AdaptiveActionMixin, AdaptiveElementMixin, ProviderScopeMixin {
  /// Resolved `Action.OpenUrlDialog` handler from the action type registry.
  late GenericActionOpenUrlDialog action;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    action =
        actionTypeRegistry.getActionForType(
              map: adaptiveMap,
            )!
            as GenericActionOpenUrlDialog;
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
