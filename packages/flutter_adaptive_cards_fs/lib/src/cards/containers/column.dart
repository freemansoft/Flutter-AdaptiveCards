import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards_fs/src/additional.dart';
import 'package:flutter_adaptive_cards_fs/src/responsive/layout_children.dart';
import 'package:flutter_adaptive_cards_fs/src/riverpod/providers.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

///
/// https://adaptivecards.io/explorer/Column.html
/// https://learn.microsoft.com/en-us/adaptive-cards/schema-explorer/column
///
/// Renders a `Column` inside a `ColumnSet`, sizing by `width` and laying out
/// `items` vertically.
class AdaptiveColumn extends ConsumerStatefulWidget with AdaptiveElementWidgetMixin {
  /// Creates a `Column` from [adaptiveMap] within a parent `ColumnSet`.
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

  /// Whether nested text elements may render markdown.
  final bool supportMarkdown;

  @override
  AdaptiveColumnState createState() => AdaptiveColumnState();
}

/// State for [AdaptiveColumn].
class AdaptiveColumnState extends ConsumerState<AdaptiveColumn>
    with AdaptiveElementMixin, AdaptiveVisibilityMixin, ProviderScopeMixin {
  /// Child elements from the column's `items` array.
  late List<Widget> items;

  /// Parsed `width` mode: `auto`, `stretch`, `weighted`, or `px`.
  late String mode;

  /// Numeric width when [mode] is `weighted` or `px`.
  late int width;

  /// Vertical alignment of column content from `verticalContentAlignment`.
  late MainAxisAlignment verticalAlignment;

  /// Horizontal alignment of column children from `horizontalAlignment`.
  late CrossAxisAlignment horizontalAlignment;

  /// Container alignment for the column's horizontal position.
  late Alignment? containerHorizontalAlignment;

  /// Optional minimum height from `minHeight`.
  double? minHeight;

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
    horizontalAlignment = styleResolver.resolveHorzontalCrossAxisAlignment(
      adaptiveMap['horizontalAlignment'],
    );
    verticalAlignment = styleResolver.resolveVerticalMainAxisContentAlginment(
      adaptiveMap['verticalContentAlignment'],
    );

    containerHorizontalAlignment = styleResolver.resolveContainerAlignment(
      adaptiveMap['horizontalAlignment'],
    );

    minHeight = parseMinHeight(adaptiveMap['minHeight']);
  }

  @override
  Widget build(BuildContext context) {
    final double preceedingSpacing = styleResolver.resolveSpacing(
      adaptiveMap['spacing'],
    );

    // no background if we have an iamge - hmm but should we anyway?
    final backgroundColor = backgroundImageSpecified(adaptiveMap)
        ? null
        : styleResolver.resolveContainerBackgroundColor(
            style: style,
          );

    final bool hasChildren = items.isNotEmpty;
    final bool hasBackgroundImage = backgroundImageSpecified(adaptiveMap);

    Widget containerChild;
    if (!hasChildren && hasBackgroundImage) {
      // A background image should fill the column, not size to its natural
      // dimensions. Wrapping it to fill the width (height from `minHeight` /
      // the ColumnSet's stretched row band) prevents the Container's (possibly
      // inherited) `alignment` from shrinking and centering it. Kept as a
      // foreground widget — not a DecorationImage — so SVG backgrounds still
      // render. See `background_image_fill_test.dart`.
      containerChild = SizedBox(
        width: double.infinity,
        height: minHeight,
        child: getBackgroundImageFromMap(adaptiveMap) ?? const SizedBox(),
      );
    } else {
      containerChild = ChildStyler(
        adaptiveMap: adaptiveMap,
        child: buildLayoutChildren(
          layouts: adaptiveMap['layouts'] as List<dynamic>?,
          bucket: ref.watch(cardWidthBucketProvider),
          styleResolver: styleResolver,
          children: [...items.map((it) => it)],
          stackBuilder: (children) => Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: horizontalAlignment,
            mainAxisAlignment: verticalAlignment,
            children: children,
          ),
        ),
      );
    }

    final decoration = hasChildren
        ? getDecorationFromMap(
            adaptiveMap,
            backgroundColor: backgroundColor,
          )
        : BoxDecoration(color: backgroundColor);

    final Widget child = Visibility(
      visible: isVisible,
      child: SeparatorElement(
        adaptiveMap: adaptiveMap,
        child: AdaptiveTappable(
          adaptiveMap: adaptiveMap,
          child: Container(
            // we need this container to be the same size as the row element
            // so that all the columns are the same height
            // and for the decoration
            alignment: containerHorizontalAlignment,
            padding: EdgeInsets.only(left: preceedingSpacing),
            constraints: minHeight != null
                ? BoxConstraints(minHeight: minHeight!)
                : null,
            decoration: decoration,
            child: containerChild,
          ),
        ),
      ),
    );

    // Why is this here if we could have another expanded below?
    // if (!widget.supportMarkdown) {
    //   child = Expanded(child: child);
    // }

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
      // flexible required to deal with height
      result = SizedBox(
        width: width.toDouble(),
        child: child,
      );
    }

    return result;
  }
}
