import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards_fs/src/additional.dart';
import 'package:flutter_adaptive_cards_fs/src/responsive/layout_children.dart';
import 'package:flutter_adaptive_cards_fs/src/riverpod/providers.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

///
/// https://adaptivecards.io/explorer/Container.html
/// https://learn.microsoft.com/en-us/adaptive-cards/schema-explorer/container
///
/// Renders a `Container` that vertically stacks `items` with optional
/// background, spacing, and `minHeight`.
class AdaptiveContainer extends ConsumerStatefulWidget with AdaptiveElementWidgetMixin {
  /// Creates a `Container` element from [adaptiveMap].
  AdaptiveContainer({
    required this.adaptiveMap,
  }) : super(key: generateAdaptiveWidgetKey(adaptiveMap)) {
    id = loadId(adaptiveMap);
  }

  @override
  final Map<String, dynamic> adaptiveMap;

  @override
  late final String id;

  @override
  AdaptiveContainerState createState() => AdaptiveContainerState();
}

/// State for [AdaptiveContainer].
class AdaptiveContainerState extends ConsumerState<AdaptiveContainer>
    with AdaptiveElementMixin, AdaptiveVisibilityMixin, ProviderScopeMixin {
  /// Vertical alignment of child items from `verticalContentAlignment`.
  late MainAxisAlignment verticalContentAlignment;

  /// Child elements from the container's `items` array.
  late List<Widget> children;

  /// Resolved spacing between container children.
  late double spacing;

  /// Background color when no background image is specified.
  late Color? backgroundColor;

  /// Optional minimum height from `minHeight`.
  double? minHeight;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (adaptiveMap['items'] != null) {
      children = List<Map<String, dynamic>>.from(adaptiveMap['items']).map((
        child,
      ) {
        return cardTypeRegistry.getElement(
          map: child,
        );
      }).toList();
    } else {
      children = [];
    }
    spacing = styleResolver.resolveSpacing(
      adaptiveMap['spacing'],
    );

    // no background if we have an iamge - hmm but should we anyway?

    verticalContentAlignment = styleResolver
        .resolveVerticalMainAxisContentAlginment(
          adaptiveMap['verticalContentAlignment']?.toString(),
        );

    backgroundColor = backgroundImageSpecified(adaptiveMap)
        ? null
        : styleResolver.resolveContainerBackgroundColor(
            style: style,
          );

    minHeight = parseMinHeight(adaptiveMap['minHeight']);
  }

  @override
  Widget build(BuildContext context) {
    final bool hasChildren = children.isNotEmpty;
    final bool hasBackgroundImage = backgroundImageSpecified(adaptiveMap);

    Widget containerChild;
    if (!hasChildren && hasBackgroundImage) {
      // A background image should fill the container, not size to its natural
      // dimensions. Wrapping it to fill the width (height from `minHeight`)
      // keeps it covering the cell. Kept as a foreground widget — not a
      // DecorationImage — so SVG backgrounds still render. See
      // `background_image_fill_test.dart`.
      containerChild = SizedBox(
        width: double.infinity,
        height: minHeight,
        child: getBackgroundImageFromMap(adaptiveMap) ?? const SizedBox(),
      );
    } else {
      final Widget itemsLayout = buildLayoutChildren(
        layouts: adaptiveMap['layouts'] as List<dynamic>?,
        bucket: ref.watch(cardWidthBucketProvider),
        styleResolver: styleResolver,
        children: children,
        stackBuilder: (items) => Column(
          mainAxisAlignment: verticalContentAlignment,
          children: items.toList(),
        ),
      );
      containerChild = Padding(
        padding: EdgeInsets.symmetric(
          vertical: spacing,
          horizontal: spacing,
        ),
        child: itemsLayout,
      );
    }

    final decoration = hasChildren
        ? getDecorationFromMap(
            adaptiveMap,
            backgroundColor: backgroundColor,
          )
        : BoxDecoration(color: backgroundColor);

    return Visibility(
      visible: isVisible,
      child: ChildStyler(
        adaptiveMap: adaptiveMap,
        child: AdaptiveTappable(
          adaptiveMap: adaptiveMap,
          child: SeparatorElement(
            adaptiveMap: adaptiveMap,
            child: Container(
              constraints: minHeight != null
                  ? BoxConstraints(minHeight: minHeight!)
                  : null,
              decoration: decoration,
              child: containerChild,
            ),
          ),
        ),
      ),
    );
  }
}
