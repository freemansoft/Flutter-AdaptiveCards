import 'package:flutter/material.dart';

import '../../adaptive_card_element.dart';
import '../../base.dart';
import 'package:provider/provider.dart';

class AdaptiveActionShowCard extends StatefulWidget
    with AdaptiveElementWidgetMixin {
  AdaptiveActionShowCard({super.key, required this.adaptiveMap});

  final Map<String, dynamic> adaptiveMap;

  @override
  _AdaptiveActionShowCardState createState() => _AdaptiveActionShowCardState();
}

class _AdaptiveActionShowCardState extends State<AdaptiveActionShowCard>
    with AdaptiveActionMixin, AdaptiveElementMixin {
  @override
  void initState() {
    super.initState();

    Widget card = widgetState.cardRegistry.getElement(adaptiveMap["card"]);

    var _adaptiveCardElement = context.read<AdaptiveCardElementState>();
    _adaptiveCardElement.registerCard(id, card);
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTapped,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(title),
          context.watch<AdaptiveCardElementState>().currentCardId == id
              ? Icon(Icons.keyboard_arrow_up)
              : Icon(Icons.keyboard_arrow_down),
        ],
      ),
    );
  }

  @override
  void onTapped() {
    var _adaptiveCardElement = context.read<AdaptiveCardElementState>();
    _adaptiveCardElement.showCard(id);
  }
}
