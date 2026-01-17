import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards/src/additional.dart';
import 'package:flutter_adaptive_cards/src/containers/column.dart';
import 'package:flutter_adaptive_cards/src/inherited_reference_resolver.dart';

///
/// https://adaptivecards.io/explorer/ColumnSet.html
///
class AdaptiveColumnSet extends StatefulWidget with AdaptiveElementWidgetMixin {
  AdaptiveColumnSet({
    super.key,
    required this.adaptiveMap,
    required this.supportMarkdown,
  });

  @override
  final Map<String, dynamic> adaptiveMap;
  final bool supportMarkdown;

  @override
  AdaptiveColumnSetState createState() => AdaptiveColumnSetState();
}

class AdaptiveColumnSetState extends State<AdaptiveColumnSet>
    with AdaptiveElementMixin {
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
    var backgroundImageUrl = resolveBackgroundImage(
      adaptiveMap['backgroundImage'],
    )?.url;
    backgroundColor =
        InheritedReferenceResolver.of(
          context,
        ).resolver.resolveContainerBackgroundColorIfNoBackgroundImage(
          context: context,
          style: adaptiveMap['style']?.toString(),
          backgroundImageUrl: backgroundImageUrl,
        );
    horizontalAlignment = InheritedReferenceResolver.of(context).resolver
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

    return SeparatorElement(
      adaptiveMap: adaptiveMap,
      child: AdaptiveTappable(
        adaptiveMap: adaptiveMap,
        child: Container(
          decoration: getDecorationFromMap(adaptiveMap).copyWith(
            color: backgroundColor,
          ),
          child: child,
        ),
      ),
    );
  }
}
