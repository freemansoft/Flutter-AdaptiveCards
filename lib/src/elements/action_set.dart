import 'package:flutter/material.dart';

import '../adaptive_mixins.dart';
import 'actions/open_url.dart';
import 'actions/show_card.dart';
import 'actions/submit.dart';
import 'unknown.dart';

///
/// https://adaptivecards.io/explorer/ActionSet.html
///
/// This class is described as a _Container_ in the docs but is located in elements for some reason
///
class ActionSet extends StatefulWidget with AdaptiveElementWidgetMixin {
  ActionSet({super.key, required this.adaptiveMap});

  @override
  final Map<String, dynamic> adaptiveMap;

  @override
  ActionSetState createState() => ActionSetState();
}

class ActionSetState extends State<ActionSet> with AdaptiveElementMixin {
  List<Widget> actions = [];

  @override
  void initState() {
    super.initState();
    List actionMaps = adaptiveMap['actions'];
    for (var action in actionMaps) {
      actions.add(_getAction(action));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(spacing: 8.0, children: actions);
  }

  Widget _getAction(Map<String, dynamic> map) {
    String stringType = map['type'];

    switch (stringType) {
      case 'Action.ShowCard':
        return AdaptiveActionShowCard(adaptiveMap: map);
      case 'Action.OpenUrl':
        return AdaptiveActionOpenUrl(adaptiveMap: map);
      case 'Action.Submit':
      case 'Action.Execute':
        return AdaptiveActionSubmit(adaptiveMap: map);
    }

    return AdaptiveUnknown(adaptiveMap: map, type: stringType);
  }
}
