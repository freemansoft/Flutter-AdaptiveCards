import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/action/generic_action.dart';
import 'package:flutter_adaptive_cards_fs/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards_fs/src/cards/actions/icon_button.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';

//
// https://adaptivecards.io/explorer/Action.OpenUrlDialog.html
// https://adaptivecards.microsoft.com/?topic=Action.OpenUrlDialog
/// It should fetch a card set from the URL
/// and display the adaptive card returned in a dialog
class AdaptiveActionOpenUrlDialog extends StatefulWidget
    with AdaptiveElementWidgetMixin {
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

class AdaptiveActionOpenUrlDialogState
    extends State<AdaptiveActionOpenUrlDialog>
    with AdaptiveActionMixin, AdaptiveElementMixin, ProviderScopeMixin {
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
