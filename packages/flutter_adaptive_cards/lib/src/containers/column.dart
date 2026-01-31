import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/src/actions/generic_action.dart';
import 'package:flutter_adaptive_cards/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards/src/additional.dart';
import 'package:flutter_adaptive_cards/src/hostconfig/miscellaneous_configs.dart';
import 'package:flutter_adaptive_cards/src/riverpod_providers.dart';
import 'package:flutter_adaptive_cards/src/utils/utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

///
/// https://adaptivecards.io/explorer/Column.html
///
class AdaptiveColumn extends StatefulWidget with AdaptiveElementWidgetMixin {
  AdaptiveColumn({
    required this.adaptiveMap,
    required this.supportMarkdown,
  }) : super(key: generateAdaptiveWidgetKey(adaptiveMap)) {
    id = loadId(adaptiveMap);
  }

  @override
  final Map<String, dynamic> adaptiveMap;

  @override
  late final String id;

  final bool supportMarkdown;

  @override
  AdaptiveColumnState createState() => AdaptiveColumnState();
}

class AdaptiveColumnState extends State<AdaptiveColumn>
    with AdaptiveElementMixin, AdaptiveVisibilityMixin {
  late List<Widget> items;

  /// Can be "auto", "stretch" or "weighted"
  late String mode;
  late int width;

  late MainAxisAlignment verticalAlignment;
  late CrossAxisAlignment horizontalAlignment;
  late Alignment? containerHorizontalAlignment;

  GenericAction? action;

  @override
  void initState() {
    super.initState();

    final toParseWidth = adaptiveMap['width'];
    if (toParseWidth != null) {
      if (toParseWidth == 'auto') {
        mode = 'auto';
      } else if (toParseWidth == 'stretch') {
        mode = 'stretch';
      } else if (toParseWidth is int) {
        width = toParseWidth;
        mode = 'weighted';
      } else {
        var widthString = toParseWidth.toString();

        if (widthString.endsWith('px')) {
          widthString = widthString.substring(
            0,
            widthString.length - 2,
          ); // remove px
          width = int.parse(widthString);
          mode = 'px';
        } else {
          // Handle gracefully
          mode = 'auto';
        }
      }
    } else {
      mode = 'auto';
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (adaptiveMap.containsKey('selectAction')) {
      action = actionTypeRegistry.getActionForType(
        map: adaptiveMap['selectAction'],
      );
    }

    items = adaptiveMap['items'] != null
        ? List<Map<String, dynamic>>.from(adaptiveMap['items']).map((
            child,
          ) {
            return cardTypeRegistry.getElement(
              map: child,
              parentMode: mode,
            );
          }).toList()
        : [];
    horizontalAlignment = ProviderScope.containerOf(context)
        .read(styleReferenceResolverProvider)
        .resolveHorzontalCrossAxisAlignment(
          adaptiveMap['horizontalAlignment'],
        );
    verticalAlignment = ProviderScope.containerOf(context)
        .read(styleReferenceResolverProvider)
        .resolveVerticalMainAxisContentAlginment(
          adaptiveMap['verticalContentAlignment'],
        );

    containerHorizontalAlignment = ProviderScope.containerOf(context)
        .read(styleReferenceResolverProvider)
        .resolveContainerAlignment(
          adaptiveMap['horizontalAlignment'],
        );
  }

  @override
  Widget build(BuildContext context) {
    final double preceedingSpacing = SpacingsConfig.resolveSpacing(
      ProviderScope.containerOf(
        context,
      ).read(styleReferenceResolverProvider).getSpacingsConfig(),
      adaptiveMap['spacing'],
    );
    final backgroundImageUrl = resolveBackgroundImage(
      adaptiveMap['backgroundImage'],
    )?.url;
    final backgroundColor = ProviderScope.containerOf(context)
        .read(styleReferenceResolverProvider)
        .resolveContainerBackgroundColorIfNoBackgroundImage(
          context: context,
          style: adaptiveMap['style']?.toString(),
          backgroundImageUrl: backgroundImageUrl,
        );

    Widget child = Visibility(
      visible: isVisible,
      child: SeparatorElement(
        adaptiveMap: adaptiveMap,
        child: InkWell(
          onTap: () => action?.tap(
            context: context,
            rawAdaptiveCardState: rawRootCardWidgetState,
            adaptiveMap: adaptiveMap,
          ),
          child: Container(
            // we need this container to be the same size as the row element
            // so that all the columns are the same height
            alignment: containerHorizontalAlignment,
            padding: EdgeInsets.only(left: preceedingSpacing),
            decoration: getDecorationFromMap(
              adaptiveMap,
              backgroundColor: backgroundColor,
            ),
            child: ChildStyler(
              adaptiveMap: adaptiveMap,
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: horizontalAlignment,
                mainAxisAlignment: verticalAlignment,
                children: [...items.map((it) => it)],
              ),
            ),
          ),
        ),
      ),
    );

    // Why is this here if we could have another expanded below?
    if (!widget.supportMarkdown) {
      child = Expanded(child: child);
    }

    var result = child;
    assert(
      mode == 'auto' || mode == 'stretch' || mode == 'weighted' || mode == 'px',
      'Invalid mode: $mode',
    );
    if (mode == 'auto') {
      result = Flexible(child: child);
    } else if (mode == 'stretch') {
      result = Expanded(child: child);
    } else if (mode == 'weighted') {
      result = Expanded(flex: width, child: child);
    } else if (mode == 'px') {
      result = SizedBox(width: width.toDouble(), child: child);
    }

    return result;
  }
}
