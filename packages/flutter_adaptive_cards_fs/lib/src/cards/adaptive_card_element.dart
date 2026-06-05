import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards_fs/src/additional.dart';
import 'package:flutter_adaptive_cards_fs/src/cards/actions/show_card.dart';
import 'package:flutter_adaptive_cards_fs/src/riverpod/providers.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The implementation of the `AdaptiveCard` card type.
///
/// This is actually classified under _cards_ and not _elements_ in the taxonomy
/// https://adaptivecards.io/explorer/
class AdaptiveCardElement extends StatefulWidget
    with AdaptiveElementWidgetMixin {
  AdaptiveCardElement({
    required this.adaptiveMap,
    required this.listView,
  }) : super(key: generateAdaptiveWidgetKey(adaptiveMap)) {
    id = loadId(adaptiveMap);
  }

  @override
  final Map<String, dynamic> adaptiveMap;
  @override
  late final String id;

  final bool listView;

  @override
  AdaptiveCardElementState createState() => AdaptiveCardElementState();
}

class AdaptiveCardElementState extends State<AdaptiveCardElement>
    with AdaptiveElementMixin, ProviderScopeMixin {
  String? version;

  late List<Widget> bodyChildren;

  List<Widget> activeActions = [];

  // don't really need this but it's here for now
  List<AdaptiveActionShowCard> showCardActions = [];

  /// contents of adaptiveMap['cards']
  /// don't really need this but it's here for now
  List<AdaptiveCardElement> showCardTargetElements = [];

  late Axis actionsOrientation;

  /// Support only one form per AdaptiveCardElement
  final formKey = GlobalKey<FormState>();

  /// "metadata": {
  ///   "webUrl": "https://example.com/card-content"
  /// },
  String? get metadataUrl => adaptiveMap['metadata']?['webUrl']?.toString();

  @override
  void initState() {
    super.initState();

    version = adaptiveMap['version']?.toString();
    // developer.log(
    //   format('AdaptiveCardElement: {} version: {}', id, version ?? ''),
    //   name: runtimeType.toString(),
    // );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    bodyChildren =
        List<Map<String, dynamic>>.from(
              adaptiveMap['body'],
            )
            .map(
              (map) => cardTypeRegistry.getElement(
                map: map,
              ),
            )
            .toList();
    final String stringAxis = styleResolver.resolveOrientation(null);
    actionsOrientation = stringAxis == 'Vertical'
        ? Axis.vertical
        : Axis.horizontal;
  }

  /// This is for actions directly on an AdaptiveCardElement
  /// Not to be confused with actions in the body of an AdaptiveCardElement or on ActionSets
  void loadNonBodyChildren() {
    if (adaptiveMap.containsKey('actions')) {
      activeActions =
          List<Map<String, dynamic>>.from(adaptiveMap['actions'] ?? [])
              .map(
                (adaptiveMap) => cardTypeRegistry.getAction(
                  map: adaptiveMap,
                ),
              )
              .toList();
      showCardActions = List<AdaptiveActionShowCard>.from(
        activeActions.whereType<AdaptiveActionShowCard>().toList(),
      );
      showCardTargetElements = List<AdaptiveCardElement>.from(
        showCardActions
            .map(
              (action) =>
                  cardTypeRegistry.getElement(
                        map: action.adaptiveMap['card'],
                      )
                      as AdaptiveCardElement,
            )
            .toList(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // developer.log(
    //   'Building AdaptiveCardElement $id with ${bodyChildren.length} children',
    //   name: runtimeType.toString(),
    // );
    loadNonBodyChildren();

    final List<Widget> widgetChildren = bodyChildren
        .map((element) => element)
        .toList();

    Widget actionWidget;

    actionWidget = Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.start,
      direction: actionsOrientation,
      children: activeActions,
    );

    widgetChildren
      ..add(actionWidget)
      ..add(
        Consumer(
          builder: (context, ref, _) {
            final expandedId = ref.watch(expandedShowCardIdProvider);
            if (expandedId == null) return const SizedBox.shrink();
            final target = showCardTargetElements.where(
              (c) => c.id == expandedId,
            );
            if (target.isEmpty) return const SizedBox.shrink();
            return target.first;
          },
        ),
      );

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

    return ProviderScope(
      overrides: [
        adaptiveCardElementStateProvider.overrideWithValue(this),
      ],
      child: AdaptiveTappable(
        adaptiveMap: adaptiveMap,
        child: Form(key: formKey, child: result),
      ),
    );
  }
}
