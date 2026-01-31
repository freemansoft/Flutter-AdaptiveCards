import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards/src/additional.dart';
import 'package:flutter_adaptive_cards/src/containers/column.dart';
import 'package:flutter_adaptive_cards/src/riverpod_providers.dart';
import 'package:flutter_adaptive_cards/src/utils/utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

///
/// https://adaptivecards.io/explorer/ColumnSet.html
///
class AdaptiveColumnSet extends StatefulWidget with AdaptiveElementWidgetMixin {
  AdaptiveColumnSet({
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
  AdaptiveColumnSetState createState() => AdaptiveColumnSetState();
}

class AdaptiveColumnSetState extends State<AdaptiveColumnSet>
    with AdaptiveElementMixin, AdaptiveVisibilityMixin {
  List<AdaptiveColumn>? columns;
  MainAxisAlignment? horizontalAlignment;
  Color? backgroundColor;

  @override
  void initState() {
    super.initState();
    columns = List<Map<String, dynamic>>.from(adaptiveMap['columns'] ?? [])
        .map(
          (child) => AdaptiveColumn(
            adaptiveMap: child,
            supportMarkdown: widget.supportMarkdown,
          ),
        )
        .toList();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final backgroundImageUrl = resolveBackgroundImage(
      adaptiveMap['backgroundImage'],
    )?.url;
    backgroundColor =
        ProviderScope.containerOf(
              context,
            )
            .read(styleReferenceResolverProvider)
            .resolveContainerBackgroundColorIfNoBackgroundImage(
              context: context,
              style: adaptiveMap['style']?.toString(),
              backgroundImageUrl: backgroundImageUrl,
            );
    horizontalAlignment = ProviderScope.containerOf(context)
        .read(styleReferenceResolverProvider)
        .resolveHorizontalMainAxisAlginment(
          adaptiveMap['horizontalAlignment'],
        );
  }

  @override
  Widget build(BuildContext context) {
    Widget child = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: horizontalAlignment!,
      children: columns!.toList(),
    );

    if (!widget.supportMarkdown) {
      child = IntrinsicHeight(child: child);
    }

    return Visibility(
      visible: isVisible,
      child: SeparatorElement(
        adaptiveMap: adaptiveMap,
        child: AdaptiveTappable(
          adaptiveMap: adaptiveMap,
          child: Container(
            decoration: getDecorationFromMap(
              adaptiveMap,
              backgroundColor: backgroundColor,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
