import 'package:flutter/material.dart';

import '../../adaptive_mixins.dart';
import '../../generic_action.dart';

///
/// https://adaptivecards.io/explorer/Action.Submit.html
///
class AdaptiveActionSubmit extends StatefulWidget
    with AdaptiveElementWidgetMixin {
  AdaptiveActionSubmit({super.key, required this.adaptiveMap, this.color});

  @override
  final Map<String, dynamic> adaptiveMap;

  // Native styling
  final Color? color;

  @override
  AdaptiveActionSubmitState createState() => AdaptiveActionSubmitState();
}

class AdaptiveActionSubmitState extends State<AdaptiveActionSubmit>
    with AdaptiveActionMixin, AdaptiveElementMixin {
  late GenericSubmitAction action;

  @override
  void initState() {
    super.initState();
    // should this use the registry?
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
