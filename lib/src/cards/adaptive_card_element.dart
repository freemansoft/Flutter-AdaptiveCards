import 'dart:developer' as developer;
import 'package:flutter_adaptive_cards/src/inherited_reference_resolver.dart';
import 'package:format/format.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../riverpod_providers.dart';

import '../adaptive_mixins.dart';
import '../elements/actions/show_card.dart';

/// The `AdaptiveCard` card type.
/// This is actually classified under _cards_ and not _elements_ in the taxonomy
/// https://adaptivecards.io/explorer/
class AdaptiveCardElement extends StatefulWidget
    with AdaptiveElementWidgetMixin {
  AdaptiveCardElement({
    Key? key,
    required this.adaptiveMap,
    required this.listView,
  }) : super(key: UniqueKey());

  @override
  final Map<String, dynamic> adaptiveMap;
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

  late String? backgroundImage;

  final Map<String, Widget> _registeredCards = {};
  final formKey = GlobalKey<FormState>();

  void registerCard(String id, Widget it) {
    _registeredCards[id] = it;
  }

  @override
  void initState() {
    super.initState();

    version = adaptiveMap['version'];
    developer.log(
      format('AdaptiveCardElement: {} version: {}', id, (version ?? '')),
      name: runtimeType.toString(),
    );

    children =
        List<Map<String, dynamic>>.from(
          adaptiveMap['body'],
        ).map((map) => widgetState.cardRegistry.getElement(map)).toList();

    backgroundImage = adaptiveMap['backgroundImage'];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    String stringAxis = InheritedReferenceResolver.of(
      context,
    ).resolver.resolveOrientation('actionsOrientation');
    if (stringAxis == 'Horizontal') {
      actionsOrientation = Axis.horizontal;
    } else if (stringAxis == 'Vertical') {
      actionsOrientation = Axis.vertical;
    }
  }

  void loadChildren() {
    if (widget.adaptiveMap.containsKey('actions')) {
      allActions =
          List<Map<String, dynamic>>.from(widget.adaptiveMap['actions'])
              .map(
                (adaptiveMap) =>
                    widgetState.cardRegistry.getAction(adaptiveMap),
              )
              .toList();
      showCardActions = List<AdaptiveActionShowCard>.from(
        allActions.whereType<AdaptiveActionShowCard>().toList(),
      );
      cards = List<Widget>.from(
        showCardActions
            .map(
              (action) => widgetState.cardRegistry.getElement(
                action.adaptiveMap['card'],
              ),
            )
            .toList(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    loadChildren();

    List<Widget> widgetChildren = children.map((element) => element).toList();

    Widget actionWidget;
    if (actionsOrientation == Axis.vertical) {
      List<Widget> actionWidgets =
          allActions.map((action) {
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
      List<Widget> actionWidgets =
          allActions.map((action) {
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

    Widget result = Container(
      margin: const EdgeInsets.all(8.0),
      child:
          widget.listView == true
              ? ListView(shrinkWrap: true, children: widgetChildren)
              : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widgetChildren,
              ),
    );

    if (backgroundImage != null) {
      result = Stack(
        children: <Widget>[
          Positioned.fill(
            child: Image.network(backgroundImage!, fit: BoxFit.cover),
          ),
          result,
        ],
      );
    }

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
