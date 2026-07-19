import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards_fs/src/additional.dart';
import 'package:flutter_adaptive_cards_fs/src/cards/containers/column.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

///
/// https://adaptivecards.io/explorer/ColumnSet.html
/// https://learn.microsoft.com/en-us/adaptive-cards/schema-explorer/column-set
///
/// Renders a `ColumnSet` as a horizontal row of [AdaptiveColumn] children.
class AdaptiveColumnSet extends ConsumerStatefulWidget
    with AdaptiveElementWidgetMixin {
  /// Creates a `ColumnSet` from [adaptiveMap].
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

  /// Whether nested text elements may render markdown.
  final bool supportMarkdown;

  @override
  AdaptiveColumnSetState createState() => AdaptiveColumnSetState();
}

/// State for [AdaptiveColumnSet].
class AdaptiveColumnSetState extends ConsumerState<AdaptiveColumnSet>
    with AdaptiveElementMixin, AdaptiveVisibilityMixin, ProviderScopeMixin {
  /// Resolved `columns` (and optional separators) for the row.
  List<Widget>? columns;

  /// Row alignment from `horizontalAlignment`.
  MainAxisAlignment? horizontalAlignment;

  /// Background color resolved from HostConfig and column set style.
  Color? backgroundColor;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    backgroundColor = styleResolver.resolveContainerBackgroundColor(
      style: style,
      defaultStyle: null,
    );
    horizontalAlignment = styleResolver.resolveHorizontalMainAxisAlignment(
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
    final Widget child = ChildStyler(
      adaptiveMap: adaptiveMap,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: horizontalAlignment!,
          children: columns!.toList(),
        ),
      ),
    );

    // `roundedCorners` is a Microsoft Teams Adaptive Cards property (beyond
    // the base Adaptive Cards schema), documented as supported on Container,
    // ColumnSet, Column, Table, and Image — see
    // https://learn.microsoft.com/en-us/microsoftteams/platform/task-modules-and-cards/cards/cards-format.
    // The radius is HostConfig-resolved via
    // `styleResolver.resolveCornerRadius()` (default 8, see
    // `FallbackConfigs.cornerRadius`), not fixed.
    final bool roundedCorners = adaptiveMap['roundedCorners'] == true;
    final BorderRadius? borderRadius = roundedCorners
        ? BorderRadius.circular(styleResolver.resolveCornerRadius())
        : null;

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
              borderRadius: borderRadius,
            ),
            clipBehavior: roundedCorners ? Clip.antiAlias : Clip.none,
            child: child,
          ),
        ),
      ),
    );
  }
}
