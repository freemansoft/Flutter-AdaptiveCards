import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../riverpod_providers.dart';

import '../../adaptive_mixins.dart';

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

    var adaptiveCardElement = ProviderScope.containerOf(
      context,
      listen: false,
    ).read(adaptiveCardElementStateProvider);
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
          ProviderScope.containerOf(
                    context,
                    listen: false,
                  ).read(adaptiveCardElementStateProvider).currentCardId ==
                  id
              ? Icon(Icons.keyboard_arrow_up)
              : Icon(Icons.keyboard_arrow_down),
        ],
      ),
    );
  }

  @override
  void onTapped() {
    var adaptiveCardElement = ProviderScope.containerOf(
      context,
      listen: false,
    ).read(adaptiveCardElementStateProvider);
    adaptiveCardElement.showCard(id);
  }
}
