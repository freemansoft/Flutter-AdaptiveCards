import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../adaptive_mixins.dart';
import '../../cards/adaptive_card_element.dart';

///
/// https://adaptivecards.io/explorer/Action.ShowCard.html
///
class AdaptiveActionShowCard extends StatefulWidget
    with AdaptiveElementWidgetMixin {
  AdaptiveActionShowCard({super.key, required this.adaptiveMap});

  @override
  final Map<String, dynamic> adaptiveMap;

  @override
  AdaptiveActionShowCardState createState() => AdaptiveActionShowCardState();
}

class AdaptiveActionShowCardState extends State<AdaptiveActionShowCard>
    with AdaptiveActionMixin, AdaptiveElementMixin {
  @override
  void initState() {
    super.initState();

    Widget card = widgetState.cardRegistry.getElement(adaptiveMap['card']);

    var adaptiveCardElement = context.read<AdaptiveCardElementState>();
    adaptiveCardElement.registerCard(id, card);
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
              ? const Icon(Icons.keyboard_arrow_up)
              : const Icon(Icons.keyboard_arrow_down),
        ],
      ),
    );
  }

  @override
  void onTapped() {
    var adaptiveCardElement = context.read<AdaptiveCardElementState>();
    adaptiveCardElement.showCard(id);
  }
}
