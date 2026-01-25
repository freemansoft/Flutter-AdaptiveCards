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
  }) : super(key: key ?? UniqueKey());

  @override
  final Map<String, dynamic> adaptiveMap;
  @override
  final RawAdaptiveCardState widgetState;
  final bool listView;

  @override
  AdaptiveCardElementState createState() => AdaptiveCardElementState();
}

class AdaptiveCardElementState extends State<AdaptiveCardElement>
    with AdaptiveElementMixin {
  String? version;
  String? currentCardId;

  late List<Widget> children;

  List<Widget> allActions = [];

  List<AdaptiveActionShowCard> showCardActions = [];
  List<Widget> cards = [];

  late Axis actionsOrientation;

  final Map<String, Widget> _registeredCards = {};
  final formKey = GlobalKey<FormState>();

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

    children =
        List<Map<String, dynamic>>.from(
              adaptiveMap['body'],
            )
            .map(
              (map) => widgetState.cardRegistry.getElement(
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

  void loadChildren() {
    if (adaptiveMap.containsKey('actions')) {
      allActions = List<Map<String, dynamic>>.from(adaptiveMap['actions'])
          .map(
            (adaptiveMap) => widgetState.cardRegistry.getAction(
              map: adaptiveMap,
              state: widgetState,
            ),
          )
          .toList();
      showCardActions = List<AdaptiveActionShowCard>.from(
        allActions.whereType<AdaptiveActionShowCard>().toList(),
      );
      cards = List<Widget>.from(
        showCardActions
            .map(
              (action) => widgetState.cardRegistry.getElement(
                map: action.adaptiveMap['card'],
                widgetState: widgetState,
              ),
            )
            .toList(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    loadChildren();

    final List<Widget> widgetChildren = children
        .map((element) => element)
        .toList();

    Widget actionWidget;
    if (actionsOrientation == Axis.vertical) {
      final List<Widget> actionWidgets = allActions.map((action) {
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
      final List<Widget> actionWidgets = allActions.map((action) {
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
      widgetChildren.add(_registeredCards[currentCardId]!);
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
