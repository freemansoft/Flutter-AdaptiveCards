import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_plus/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards_plus/src/additional.dart';
import 'package:flutter_adaptive_cards_plus/src/containers/column.dart';
import 'package:flutter_adaptive_cards_plus/src/riverpod_providers.dart';
import 'package:flutter_adaptive_cards_plus/src/utils/utils.dart';
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
  List<Widget>? columns;
  MainAxisAlignment? horizontalAlignment;
  Color? backgroundColor;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    backgroundColor =
        ProviderScope.containerOf(
              context,
            )
            .read(styleReferenceResolverProvider)
            .resolveContainerBackgroundColor(
              style: style,
              defaultStyle: null,
            );
    horizontalAlignment = ProviderScope.containerOf(context)
        .read(styleReferenceResolverProvider)
        .resolveHorizontalMainAxisAlignment(
          adaptiveMap['horizontalAlignment'],
        );

    // this is missing the type check for 'column'
    // should this use the card registry to create the columns?
    columns = List<Map<String, dynamic>>.from(adaptiveMap['columns'] ?? [])
        .expand((
          child,
        ) {
          final separator = child['separator'] as bool? ?? false;
          return [
            if (separator) const VerticalDivider(),
            AdaptiveColumn(
              adaptiveMap: child,
              supportMarkdown: widget.supportMarkdown,
            ),
          ];
        })
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    // developer.log(
    //   'Building ColumnSet $id with ${columns!.length} columns',
    //   name: runtimeType.toString(),
    // );
    final Widget child = IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: horizontalAlignment!,
        children: columns!.toList(),
      ),
    );

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
