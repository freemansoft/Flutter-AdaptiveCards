import 'package:flutter/material.dart';

import '../../adaptive_mixins.dart';
import '../../generic_action.dart';
import 'icon_button.dart';

///
/// https://adaptivecards.io/explorer/Action.OpenUrl.html
///
class AdaptiveActionOpenUrl extends StatefulWidget
    with AdaptiveElementWidgetMixin {
  AdaptiveActionOpenUrl({super.key, required this.adaptiveMap});

  @override
  final Map<String, dynamic> adaptiveMap;

  @override
  AdaptiveActionOpenUrlState createState() => AdaptiveActionOpenUrlState();
}

class AdaptiveActionOpenUrlState extends State<AdaptiveActionOpenUrl>
    with AdaptiveActionMixin, AdaptiveElementMixin {
  late GenericActionOpenUrl action;
  late String? iconUrl;

  @override
  void initState() {
    super.initState();

    action = GenericActionOpenUrl(adaptiveMap, widgetState);
    iconUrl = adaptiveMap['iconUrl'];
  }

  @override
  Widget build(BuildContext context) {
    // TODO IconButtonAction ??
    return IconButtonAction(
      adaptiveMap: adaptiveMap,
      onTapped: onTapped,
    );
  }

  @override
  void onTapped() {
    action.tap();
  }
}
