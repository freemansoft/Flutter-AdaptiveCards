import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards/src/elements/actions/icon_button.dart';

class AdaptiveActionOpenUrlDialog extends StatefulWidget
    with AdaptiveElementWidgetMixin {
  AdaptiveActionOpenUrlDialog({super.key, required this.adaptiveMap});

  @override
  final Map<String, dynamic> adaptiveMap;

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
    url = widget.adaptiveMap['url'];
  }

  @override
  Widget build(BuildContext context) {
    return IconButtonAction(
      adaptiveMap: widget.adaptiveMap,
      onTapped: onTapped,
    );
  }

  @override
  void onTapped() {
    if (url != null) {
      // Show dialog with URL
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Open URL'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('This action would open:'),
                Text(url!, style: TextStyle(color: Colors.blue)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close'),
              ),
              TextButton(
                onPressed: () {
                  // Actually open it?
                  widgetState.openUrl(url!);
                  Navigator.pop(context);
                },
                child: Text('Open'),
              ),
            ],
          );
        },
      );
    }
  }
}
