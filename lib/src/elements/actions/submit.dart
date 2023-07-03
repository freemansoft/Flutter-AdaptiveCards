///
/// https://adaptivecards.io/explorer/Action.Submit.html
///
import 'package:flutter/material.dart';

import '../../base.dart';

class AdaptiveActionSubmit extends StatefulWidget
    with AdaptiveElementWidgetMixin {
  AdaptiveActionSubmit({super.key, required this.adaptiveMap, this.color});

  final Map<String, dynamic> adaptiveMap;

  // Native styling
  final Color? color;

  @override
  _AdaptiveActionSubmitState createState() => _AdaptiveActionSubmitState();
}

class _AdaptiveActionSubmitState extends State<AdaptiveActionSubmit>
    with AdaptiveActionMixin, AdaptiveElementMixin {
  late GenericSubmitAction action;

  @override
  void initState() {
    super.initState();
    action = GenericSubmitAction(adaptiveMap, widgetState);
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: widget.color, // Background color
        // minimumSize: const Size.fromHeight(50),
      ),
      onPressed: onTapped,
      child: Text(title, textAlign: TextAlign.center),
    );
  }

  @override
  void onTapped() {
    action.tap();
  }
}
