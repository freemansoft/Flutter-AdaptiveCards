import 'dart:developer' as developer;
import 'package:format/format.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'base.dart';
import 'elements/actions/show_card.dart';

class AdaptiveCardElement extends StatefulWidget
    with AdaptiveElementWidgetMixin {
  AdaptiveCardElement(
      {Key? key, required this.adaptiveMap, required this.listView})
      : super(key: UniqueKey());

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

  Map<String, Widget> _registeredCards = {};
  final formKey = GlobalKey<FormState>();

  void registerCard(String id, Widget it) {
    _registeredCards[id] = it;
  }

  @override
  void initState() {
    super.initState();

    version = adaptiveMap['version'];
    developer.log(format(
        "AdaptiveCardElement: {} version: {}", this.id, (version ?? '')));

    String stringAxis = resolver.resolve("actions", "actionsOrientation");
    if (stringAxis == "Horizontal")
      actionsOrientation = Axis.horizontal;
    else if (stringAxis == "Vertical") actionsOrientation = Axis.vertical;

    children = List<Map<String, dynamic>>.from(adaptiveMap["body"])
        .map((map) => widgetState.cardRegistry.getElement(map))
        .toList();

    backgroundImage = adaptiveMap['backgroundImage'];
  }

  void loadChildren() {
    if (widget.adaptiveMap.containsKey("actions")) {
      allActions = List<Map<String, dynamic>>.from(
              widget.adaptiveMap["actions"])
          .map((adaptiveMap) => widgetState.cardRegistry.getAction(adaptiveMap))
          .toList();
      showCardActions = List<AdaptiveActionShowCard>.from(allActions
          .where((action) => action is AdaptiveActionShowCard)
          .toList());
      cards = List<Widget>.from(showCardActions
          .map((action) =>
              widgetState.cardRegistry.getElement(action.adaptiveMap["card"]))
          .toList());
    }
  }

  @override
  Widget build(BuildContext context) {
    loadChildren();

    List<Widget> widgetChildren = children.map((element) => element).toList();

    Widget actionWidget;
    if (actionsOrientation == Axis.vertical) {
      List<Widget> actionWidgets = allActions.map((action) {
        return SizedBox(
          width: double.infinity,
          child: action,
        );
      }).toList();

      actionWidget = Row(children: [
        Expanded(
          child: Column(
            children: actionWidgets,
            crossAxisAlignment: CrossAxisAlignment.start,
          ),
        )
      ]);
    } else {
      List<Widget> actionWidgets = allActions.map((action) {
        return Padding(
          padding: EdgeInsets.only(right: 8),
          child: action,
        );
      }).toList();

      actionWidget = Row(
        children: actionWidgets,
        crossAxisAlignment: CrossAxisAlignment.start,
      );
    }
    widgetChildren.add(actionWidget);

    if (currentCardId != null) {
      widgetChildren.add(_registeredCards[currentCardId]!);
    }

    Widget result = Container(
      margin: const EdgeInsets.all(8.0),
      child: widget.listView == true
          ? ListView(
              shrinkWrap: true,
              children: widgetChildren,
            )
          : Column(
              children: widgetChildren,
              crossAxisAlignment: CrossAxisAlignment.start,
            ),
    );

    if (backgroundImage != null) {
      result = Stack(
        children: <Widget>[
          Positioned.fill(
            child: Image.network(
              backgroundImage!,
              fit: BoxFit.cover,
            ),
          ),
          result,
        ],
      );
    }

    return Provider<AdaptiveCardElementState>.value(
      value: this,
      child: Form(key: formKey, child: result),
    );
  }

  /// This is called when an [_AdaptiveActionShowCard] triggers it.
  void showCard(String id) {
    if (currentCardId == id) {
      currentCardId = null;
    } else {
      currentCardId = id;
    }
    setState(() {});
  }
}
