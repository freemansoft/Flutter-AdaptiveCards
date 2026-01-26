import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards/src/additional.dart';
import 'package:flutter_adaptive_cards/src/cards/adaptive_card_element.dart';
import 'package:flutter_adaptive_cards/src/flutter_raw_adaptive_card.dart';
import 'package:flutter_adaptive_cards/src/inherited_reference_resolver.dart';
import 'package:flutter_adaptive_cards/src/riverpod_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:format/format.dart';

///
/// https://adaptivecards.io/explorer/Action.ShowCard.html
///

class AdaptiveActionShowCard extends StatefulWidget
    with AdaptiveElementWidgetMixin {
  AdaptiveActionShowCard({
    super.key,
    required this.adaptiveMap,
    required this.widgetState,
  }) {
    id = loadId(adaptiveMap);
  }

  @override
  final Map<String, dynamic> adaptiveMap;

  @override
  final RawAdaptiveCardState widgetState;

  @override
  late final String id;

  @override
  AdaptiveActionShowCardState createState() => AdaptiveActionShowCardState();
}

class AdaptiveActionShowCardState extends State<AdaptiveActionShowCard>
    with AdaptiveActionMixin, AdaptiveElementMixin {
  String targetCardId = '';

  @override
  void initState() {
    super.initState();

    // we cache the show card widget because it isn't in the tree if hidden (not visible)
    // should this be in didChangeDependencies instead?
    final Widget targetCard = widgetState.cardTypeRegistry.getElement(
      map: adaptiveMap['card'],
      widgetState: widgetState,
    );
    if (targetCard is AdaptiveCardElement) {
      targetCardId = targetCard.id;
      assert(() {
        developer.log(
          format(
            'targetCard for {} has id {} built for {}',
            id,
            targetCard.id,
            targetCard,
          ),
          name: runtimeType.toString(),
        );
        return true;
      }());
    }

    ProviderScope.containerOf(
          context,
          listen: false,
        )
        .read(adaptiveCardElementStateProvider)
        .registerCard(targetCardId, targetCard);
  }

  @override
  Widget build(BuildContext context) {
    final resolver = InheritedReferenceResolver.of(context).resolver;

    return SeparatorElement(
      adaptiveMap: adaptiveMap,
      widgetState: widgetState,
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
    ).read(adaptiveCardElementStateProvider).showCard(targetCardId);
  }
}
