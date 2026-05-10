import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards_fs/src/additional.dart';
import 'package:flutter_adaptive_cards_fs/src/cards/adaptive_card_element.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';

///
/// https://adaptivecards.io/explorer/Action.ShowCard.html
///

class AdaptiveActionShowCard extends StatefulWidget
    with AdaptiveElementWidgetMixin {
  AdaptiveActionShowCard({
    required this.adaptiveMap,
  }) : super(key: generateAdaptiveWidgetKey(adaptiveMap)) {
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
    with
        AdaptiveActionMixin,
        AdaptiveElementMixin,
        AdaptiveVisibilityMixin,
        ProviderScopeMixin {
  AdaptiveCardElement? targetCard;

  @override
  void didChangeDependencies() {
    // we cache the target of the show card widget
    // because it isn't in the tree if hidden (not visible)
    // should this be in didChangeDependencies instead?
    final Widget possibleTargetCard = cardTypeRegistry.getElement(
      map: adaptiveMap['card'],
    );
    if (possibleTargetCard is AdaptiveCardElement) {
      // AdaptiveCard Element doesn't actually have natural id in the map
      // so it won't be registered by default
      // for show card, though we know the AdaptiveCard Element
      // needs to be registered because we need to show/hide it
      // in this case we override that behavior when getElement is called
      targetCard = possibleTargetCard;
      // this feels like a hack because it should have gotten called when created
      // do we need it because dependenciesDidChange doesn't get called so the mixin doesn't fire?
      adaptiveCardElementState.registerCardWidget(targetCard!.id, targetCard!);
      assert(() {
        developer.log(
          'targetCard of $id has id ${possibleTargetCard.id} built for $possibleTargetCard',
          name: runtimeType.toString(),
        );
        return true;
      }());
    } else if (possibleTargetCard is AdaptiveElementWidgetMixin) {
      // we have a card but not the mandatory type
      assert(() {
        developer.log(
          'target card Time must be AdaptiveCardElement for $id built for $possibleTargetCard',
          name: runtimeType.toString(),
        );
        return true;
      }());
    }
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    final resolver = styleResolver;

    final theButton = ElevatedButton(
      onPressed: () {
        if (targetCard != null) {
          adaptiveCardElementState.showCard(targetCard!);
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: resolver.resolveButtonBackgroundColor(
          context: context,
          style: style,
        ),
        foregroundColor: resolver.resolveButtonForegroundColor(
          context: context,
          style: style,
        ),
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
    );

    final wrappedButton = (tooltip != null)
        ? Tooltip(
            message: tooltip,
            child: theButton,
          )
        : theButton;

    return Visibility(
      visible: isVisible,
      child: SeparatorElement(
        adaptiveMap: adaptiveMap,
        child: wrappedButton,
      ),
    );
  }
}
