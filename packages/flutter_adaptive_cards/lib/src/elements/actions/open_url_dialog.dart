import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards/src/elements/actions/icon_button.dart';
import 'package:flutter_adaptive_cards/src/flutter_raw_adaptive_card.dart';

///
/// https://adaptivecards.io/explorer/Action.OpenUrlDialog.html
/// TODO(username): Not implemented correctly.
/// It should fetch a card set from the URL
/// and display the adaptive card returned in a dialog
class AdaptiveActionOpenUrlDialog extends StatefulWidget
    with AdaptiveElementWidgetMixin {
  AdaptiveActionOpenUrlDialog({
    super.key,
    required this.adaptiveMap,
    required this.widgetState,
  });

  @override
  final Map<String, dynamic> adaptiveMap;

  @override
  final RawAdaptiveCardState widgetState;

  @override
  AdaptiveActionOpenUrlDialogState createState() =>
      AdaptiveActionOpenUrlDialogState();
}

class AdaptiveActionOpenUrlDialogState
    extends State<AdaptiveActionOpenUrlDialog>
    with AdaptiveActionMixin, AdaptiveElementMixin {
  late String? url;

  @override
  void initState() {
    super.initState();
    url = adaptiveMap['url'] as String?;
  }

  @override
  Widget build(BuildContext context) {
    return IconButtonAction(
      adaptiveMap: adaptiveMap,
      onTapped: onTapped,
      widgetState: widgetState,
    );
  }

  @override
  void onTapped() {
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
                    widgetState.openUrl(url!);
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
  }
}
