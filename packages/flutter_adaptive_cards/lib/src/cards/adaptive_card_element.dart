import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards/src/additional.dart';
import 'package:flutter_adaptive_cards/src/elements/actions/show_card.dart';
import 'package:flutter_adaptive_cards/src/flutter_raw_adaptive_card.dart';
import 'package:flutter_adaptive_cards/src/inherited_reference_resolver.dart';
import 'package:flutter_adaptive_cards/src/riverpod_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:format/format.dart';

/// The implementation of the `AdaptiveCard` card type.
///
/// This is actually classified under _cards_ and not _elements_ in the taxonomy
/// https://adaptivecards.io/explorer/
class AdaptiveCardElement extends StatefulWidget
    with AdaptiveElementWidgetMixin {
  AdaptiveCardElement({
    Key? key,
    required this.adaptiveMap,
    required this.widgetState,
    required this.listView,
  }) : super(key: key ?? UniqueKey()) {
    id = loadId(adaptiveMap);
  }

  @override
  final Map<String, dynamic> adaptiveMap;
  @override
  final RawAdaptiveCardState widgetState;
  @override
  late final String id;

  final bool listView;

  @override
  AdaptiveCardElementState createState() => AdaptiveCardElementState();
}

class AdaptiveCardElementState extends State<AdaptiveCardElement>
    with AdaptiveElementMixin {
  String? version;

  /// The current card that is being shown via a showCard action
  String? currentCardId;

  late List<Widget> bodyChildren;

  List<Widget> activeActions = [];

  // don't really need this but it's here for now
  List<AdaptiveActionShowCard> showCardActions = [];

  /// contents of adaptiveMap['cards']
  /// don't really need this but it's here for now
  List<AdaptiveCardElement> showCardTargetElements = [];

  late Axis actionsOrientation;

  /// Cards that exist under the AdaptiveCardElement by ID
  final Map<String, Widget> _registeredCards = {};

  /// Support only one form per AdaptiveCardElement
  final formKey = GlobalKey<FormState>();

  /// Register a card to the registry so we can refer to it later
  /// We want all cards that have a user provided id to be registered
  /// We also register the adaptive Card element itself because showCard
  /// actions target an AdaptiveCardElement which does not have an id
  void registerCard(String registrationId, Widget it) {
    // this is a hack because it was hard to make this a generic widget
    // had the same problem with Selectable but made it a stateless widget
    if (it is AdaptiveTappable) {
      return;
    }
    _registeredCards[registrationId] = it;
    assert(() {
      developer.log(
        format('Registered card with id:{} type:{}', registrationId, it),
        name: runtimeType.toString(),
      );
      return true;
    }());
  }

  /// Unregister a card from the registry so we don't refer to it after it's been disposed
  void unregisterCard(
    String registrationId,
  ) {
    if (_registeredCards.containsKey(registrationId)) {
      _registeredCards.remove(registrationId);
      assert(() {
        developer.log(
          format(
            'Unregistered card with id:{} ',
            registrationId,
          ),
          name: runtimeType.toString(),
        );
        return true;
      }());
    }
  }

  @override
  void initState() {
    super.initState();

    version = adaptiveMap['version']?.toString();
    // developer.log(
    //   format('AdaptiveCardElement: {} version: {}', id, version ?? ''),
    //   name: runtimeType.toString(),
    // );

    bodyChildren =
        List<Map<String, dynamic>>.from(
              adaptiveMap['body'],
            )
            .map(
              (map) => widgetState.cardTypeRegistry.getElement(
                map: map,
                widgetState: widgetState,
              ),
            )
            .toList();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final String stringAxis = InheritedReferenceResolver.of(
      context,
    ).resolver.resolveOrientation('actionsOrientation');
    if (stringAxis == 'Horizontal') {
      actionsOrientation = Axis.horizontal;
    } else if (stringAxis == 'Vertical') {
      actionsOrientation = Axis.vertical;
    }
  }

  /// This is for actions directly on an AdaptiveCardElement
  /// Not to be confused with actions in the body of an AdaptiveCardElement or on ActionSets
  void loadNonBodyChildren() {
    if (adaptiveMap.containsKey('actions')) {
      activeActions =
          List<Map<String, dynamic>>.from(adaptiveMap['actions'] ?? [])
              .map(
                (adaptiveMap) => widgetState.cardTypeRegistry.getAction(
                  map: adaptiveMap,
                  state: widgetState,
                ),
              )
              .toList();
      showCardActions = List<AdaptiveActionShowCard>.from(
        activeActions.whereType<AdaptiveActionShowCard>().toList(),
      );
      showCardTargetElements = List<AdaptiveCardElement>.from(
        showCardActions
            .map(
              (action) => widgetState.cardTypeRegistry.getElement(
                map: action.adaptiveMap['card'],
                widgetState: widgetState,
              ),
            )
            .toList(),
      );
      assert(() {
        if (showCardActions.isNotEmpty) {
          developer.log(
            format(
              'showCardElements for {} constructed to {}',
              id,
              showCardTargetElements.map((card) => card.id).toList(),
            ),
            name: runtimeType.toString(),
          );
        }
        return true;
      }());
    }
  }

  @override
  Widget build(BuildContext context) {
    loadNonBodyChildren();

    final List<Widget> widgetChildren = bodyChildren
        .map((element) => element)
        .toList();

    Widget actionWidget;
    if (actionsOrientation == Axis.vertical) {
      final List<Widget> actionWidgets = activeActions.map((action) {
        return SizedBox(width: double.infinity, child: action);
      }).toList();

      actionWidget = Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: actionWidgets,
            ),
          ),
        ],
      );
    } else {
      final List<Widget> actionWidgets = activeActions.map((action) {
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: action,
        );
      }).toList();

      actionWidget = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: actionWidgets,
      );
    }
    widgetChildren.add(actionWidget);

    if (currentCardId != null) {
      final foundCard = _registeredCards[currentCardId];
      if (foundCard != null) {
        widgetChildren.add(foundCard);
      }
    }

    // default to result without a background image
    Widget result = Container(
      margin: const EdgeInsets.all(8),
      child: widget.listView
          ? ListView(shrinkWrap: true, children: widgetChildren)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: widgetChildren,
            ),
    );

    final backgroundImage = getBackgroundImageFromMap(adaptiveMap);

    // replace the result with a stack if there is a background image
    if (backgroundImage != null) {
      // wrap result in a stack with the background image
      result = Stack(
        children: <Widget>[
          Positioned.fill(
            child: backgroundImage,
          ),
          result,
        ],
      );
    }

    // provider always wraps the result object
    return ProviderScope(
      overrides: [
        adaptiveCardElementStateProvider.overrideWithValue(this),
      ],
      child: Form(key: formKey, child: result),
    );
  }

  /// This is called when an [AdaptiveActionShowCard] triggers it.
  void showCard(String id) {
    if (currentCardId == id) {
      currentCardId = null;
    } else {
      currentCardId = id;
    }
    setState(() {});
  }
}
