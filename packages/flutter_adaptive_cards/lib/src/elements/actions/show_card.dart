import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards/src/additional.dart';
import 'package:flutter_adaptive_cards/src/cards/adaptive_card_element.dart';
import 'package:flutter_adaptive_cards/src/inherited_reference_resolver.dart';
import 'package:flutter_adaptive_cards/src/utils/utils.dart';
import 'package:format/format.dart';

///
/// https://adaptivecards.io/explorer/Action.ShowCard.html
///

class AdaptiveActionShowCard extends StatefulWidget
    with AdaptiveElementWidgetMixin {
  AdaptiveActionShowCard({
    required this.adaptiveMap,
  }) : super(key: generateWidgetKey(adaptiveMap)) {
    id = loadId(adaptiveMap);
  }

  @override
  final Map<String, dynamic> adaptiveMap;

  @override
  late final String id;

  @override
  AdaptiveActionShowCardState createState() => AdaptiveActionShowCardState();
}

class AdaptiveActionShowCardState extends State<AdaptiveActionShowCard>
    with AdaptiveActionMixin, AdaptiveElementMixin, AdaptiveVisibilityMixin {
  AdaptiveCardElement? targetCard;

  @override
  void didChangeDependencies() {
    // we cache the show card widget because it isn't in the tree if hidden (not visible)
    // should this be in didChangeDependencies instead?
    final Widget possibleTargetCard = cardTypeRegistry.getElement(
      map: adaptiveMap['card'],
    );
    if (possibleTargetCard is AdaptiveCardElement) {
      targetCard = possibleTargetCard;
      // this feels like a hack because it should have gotten called when created
      // do we need it because dependenciesDidChange doesn't get called so the mixin doesn't fire?
      adaptiveCardElementState.registerCardWidget(targetCard!.id, targetCard!);
      assert(() {
        developer.log(
          format(
            'targetCard for {} has id {} built for {}',
            id,
            possibleTargetCard.id,
            possibleTargetCard,
          ),
          name: runtimeType.toString(),
        );
        return true;
      }());
    } else if (possibleTargetCard is AdaptiveElementWidgetMixin) {
      // we have a card but not the mandatory type
      assert(() {
        developer.log(
          format(
            'target card Time must be AdaptiveCardElement for {} built for {}',
            id,
            possibleTargetCard,
          ),
          name: runtimeType.toString(),
        );
        return true;
      }());
    }
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    final resolver = InheritedReferenceResolver.of(context).resolver;

    return Visibility(
      visible: isVisible,
      child: SeparatorElement(
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
              // chevron state based on if our card being shown
              if (adaptiveCardElementState.currentCard != targetCard)
                const Icon(Icons.keyboard_arrow_up)
              else
                const Icon(Icons.keyboard_arrow_down),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void onTapped() {
    if (targetCard != null) {
      adaptiveCardElementState.showCard(targetCard!);
    }
  }
}
