import 'package:flutter/material.dart';

import '../../adaptive_card_element.dart';
import '../../base.dart';

class AdaptiveActionShowCard extends StatefulWidget with AdaptiveElementWidgetMixin {
  AdaptiveActionShowCard({Key key, this.adaptiveMap}) : super(key: key);

  final Map adaptiveMap;

  @override
  _AdaptiveActionShowCardState createState() => _AdaptiveActionShowCardState();
}

class _AdaptiveActionShowCardState extends State<AdaptiveActionShowCard>
    with AdaptiveActionMixin, AdaptiveElementMixin {
  @override
  void initState() {
    super.initState();

    Widget card = widgetState.cardRegistry.getElement(adaptiveMap["card"]);

    var _adaptiveCardElement = AdaptiveCardElementState.of(context);
    if (_adaptiveCardElement != null) {
      _adaptiveCardElement.registerCard(id, card);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RaisedButton(
      onPressed: onTapped,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(title),
          AdaptiveCardElementState.of(context).currentCardId == id
              ? Icon(Icons.keyboard_arrow_up)
              : Icon(Icons.keyboard_arrow_down),
        ],
      ),
    );
  }

  @override
  void onTapped() {
    var _adaptiveCardElement = AdaptiveCardElementState.of(context);
    if (_adaptiveCardElement != null) {
      _adaptiveCardElement.showCard(id);
    }
  }
}
