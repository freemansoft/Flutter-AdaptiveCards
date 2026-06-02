import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards_fs/src/additional.dart';
import 'package:flutter_adaptive_cards_fs/src/cards/adaptive_card_element.dart';
import 'package:flutter_adaptive_cards_fs/src/riverpod/providers.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

///
/// https://adaptivecards.io/explorer/Action.ShowCard.html
///

class AdaptiveActionShowCard extends ConsumerStatefulWidget
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

class AdaptiveActionShowCardState extends ConsumerState<AdaptiveActionShowCard>
    with
        AdaptiveActionMixin,
        AdaptiveElementMixin,
        AdaptiveVisibilityMixin,
        ProviderScopeMixin {
  AdaptiveCardElement? targetCard;
  String? _targetCardId;

  @override
  void didChangeDependencies() {
    // we cache the target of the show card widget
    // because it isn't in the tree if hidden (not visible)
    // should this be in didChangeDependencies instead?
    final Widget possibleTargetCard = cardTypeRegistry.getElement(
      map: adaptiveMap['card'],
    );
    if (possibleTargetCard is AdaptiveCardElement) {
      targetCard = possibleTargetCard;
      _targetCardId = possibleTargetCard.id;
    } else if (possibleTargetCard is AdaptiveElementWidgetMixin) {
      // we have a card but not the mandatory type
      _targetCardId = null;
    }
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    final resolver = styleResolver;
    final expandedId = ref.watch(expandedShowCardIdProvider);

    final theButton = ElevatedButton(
      onPressed: () {
        final targetId = _targetCardId;
        if (targetId == null) return;
        ref.read(expandedShowCardIdProvider.notifier).toggle(targetId);
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
          if (expandedId != _targetCardId)
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
