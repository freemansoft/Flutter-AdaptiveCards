import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards/src/additional.dart';
import 'package:flutter_adaptive_cards/src/inherited_reference_resolver.dart';
import 'package:flutter_adaptive_cards/src/riverpod_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

    final Widget card = widgetState.cardRegistry.getElement(
      adaptiveMap['card'],
    );

    ProviderScope.containerOf(
      context,
      listen: false,
    ).read(adaptiveCardElementStateProvider).registerCard(id, card);
  }

  @override
  Widget build(BuildContext context) {
    final resolver = InheritedReferenceResolver.of(context).resolver;

    return SeparatorElement(
      adaptiveMap: adaptiveMap,
      child: ElevatedButton(
        onPressed: onTapped,
        style: ElevatedButton.styleFrom(
          backgroundColor: resolver.resolveButtonBackgroundColor(
            context: context,
            style: adaptiveMap['style'],
          ),
          foregroundColor: resolver.resolveButtonForegroundColor(
            context: context,
            style: adaptiveMap['style'],
          ),
          // minimumSize: const Size.fromHeight(50),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(title),
            if (ProviderScope.containerOf(
                  context,
                  listen: false,
                ).read(adaptiveCardElementStateProvider).currentCardId ==
                id)
              const Icon(Icons.keyboard_arrow_up)
            else
              const Icon(Icons.keyboard_arrow_down),
          ],
        ),
      ),
    );
  }

  @override
  void onTapped() {
    ProviderScope.containerOf(
      context,
      listen: false,
    ).read(adaptiveCardElementStateProvider).showCard(id);
  }
}
