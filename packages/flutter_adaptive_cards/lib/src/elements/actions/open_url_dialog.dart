import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/src/actions/generic_action.dart';
import 'package:flutter_adaptive_cards/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards/src/elements/actions/icon_button.dart';
import 'package:flutter_adaptive_cards/src/utils/utils.dart';

//
// https://adaptivecards.io/explorer/Action.OpenUrlDialog.html
// TODO(username): Not implemented correctly.
/// It should fetch a card set from the URL
/// and display the adaptive card returned in a dialog
class AdaptiveActionOpenUrlDialog extends StatefulWidget
    with AdaptiveElementWidgetMixin {
  AdaptiveActionOpenUrlDialog({
    required this.adaptiveMap,
  }) : super(key: generateAdaptiveWidgetKey(adaptiveMap)) {
    id = loadId(adaptiveMap);
  }

  @override
  final Map<String, dynamic> adaptiveMap;

  @override
  late final String id;

  @override
  AdaptiveActionOpenUrlDialogState createState() =>
      AdaptiveActionOpenUrlDialogState();
}

class AdaptiveActionOpenUrlDialogState
    extends State<AdaptiveActionOpenUrlDialog>
    with AdaptiveActionMixin, AdaptiveElementMixin {
  late String? url;
  late GenericActionOpenUrl action;

  @override
  void initState() {
    super.initState();
    url = adaptiveMap['url'] as String?;
  }

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
        if (url != null) {
          // Show dialog with URL
          unawaited(
            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text('Open URL'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('This action would open:'),
                      Text(url!, style: const TextStyle(color: Colors.blue)),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                    TextButton(
                      onPressed: () {
                        // Actually open it?
                        action.tap(
                          context: context,
                          rawAdaptiveCardState: rawRootCardWidgetState,
                          adaptiveMap: adaptiveMap,
                        );
                        Navigator.pop(context);
                      },
                      child: const Text('Open'),
                    ),
                  ],
                );
              },
            ),
          );
        }
      },
    );
  }
}
