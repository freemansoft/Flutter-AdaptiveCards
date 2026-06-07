import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/action/generic_action.dart';
import 'package:flutter_adaptive_cards_fs/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards_fs/src/reference_resolver.dart';
import 'package:flutter_adaptive_cards_fs/src/riverpod/providers.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Additional widget classes used to frame out the rendering of cards
// Not part of the Adaptive-card standard

/// Class that adds a separator to the element
class SeparatorElement extends StatelessWidget {
  const SeparatorElement({
    super.key,
    required this.adaptiveMap,
    required this.child,
  });

  final Map<String, dynamic> adaptiveMap;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final resolver = ProviderScope.containerOf(context).read(
      styleReferenceResolverProvider,
    );
    final topSpacing = resolver.resolveSpacing(adaptiveMap['spacing']);

    final separator = adaptiveMap['separator'] as bool? ?? false;
    if (!separator) {
      if (adaptiveMap['type']?.toString().toLowerCase() == 'column') {
        // columns don't have spacing at the top
        return child;
      } else {
        return Container(
          padding: EdgeInsets.only(top: topSpacing),
          child: child,
        );
      }
    } else {
      // separator is true
      final color = resolver.resolveSeparatorColor();
      final thickness = resolver.resolveSeparatorThickness();

      if (adaptiveMap['type']?.toString().toLowerCase() == 'column') {
        // Column dividers happen at the ColumnSet level
        return child;
      } else {
        // separator is true and not a column
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Divider(
              height: topSpacing,
              thickness: thickness,
              color: color,
            ),
            child,
          ],
        );
      }
    }
  }
}

/// Implements selectAction for any element
/// Not really an Adaptive card element so we generate one-off keys for it
/// Used in Image, Container, Column, columnSet, adaptiveCard, etc.
class AdaptiveTappable extends StatefulWidget with AdaptiveElementWidgetMixin {
  factory AdaptiveTappable({
    required Widget child,
    required Map<String, dynamic> adaptiveMap,
  }) {
    final uniqueId = UUIDGenerator().generateUniqueId(
      type: adaptiveMap['type'],
    );
    return AdaptiveTappable._(
      adaptiveMap: adaptiveMap,
      id: uniqueId,
      key: ValueKey<String>(uniqueId),
      child: child,
    );
  }

  AdaptiveTappable._({
    super.key,
    required this.adaptiveMap,
    required this.id,
    required this.child,
  });

  final Widget child;

  @override
  final Map<String, dynamic> adaptiveMap;

  /// overrides the abstract id in adaptiveElementMixin
  @override
  final String id;

  @override
  AdaptiveTappableState createState() => AdaptiveTappableState();
}

class AdaptiveTappableState extends State<AdaptiveTappable>
    with AdaptiveElementMixin, ProviderScopeMixin {
  GenericAction? action;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The selectAction could be anyone of the action types
    if (adaptiveMap.containsKey('selectAction')) {
      action = actionTypeRegistry.getActionForType(
        map: adaptiveMap['selectAction'],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return action == null
        ? widget.child
        : InkWell(
            onTap: () => action?.tap(
              context: context,
              rawAdaptiveCardState: rawRootCardWidgetState,
              adaptiveMap: adaptiveMap['selectAction'],
            ),
            child: widget.child,
          );
  }
}

/// Used in some containers to change the style from there on down
class ChildStyler extends StatelessWidget {
  const ChildStyler({
    super.key,
    required this.child,
    required this.adaptiveMap,
  });
  final Widget child;

  final Map<String, dynamic> adaptiveMap;

  @override
  Widget build(BuildContext context) {
    final parent = ProviderScope.containerOf(
      context,
    ).read(styleReferenceResolverProvider);

    final childResolver = parent.copyWith(
      inheritedContainerStyle:
          ReferenceResolver.inheritedContainerStyleForChildren(
            parentInherited: parent.inheritedContainerStyle,
            ownContainerStyle: adaptiveMap['style'] as String?,
          ),
      inheritedHorizontalAlignment:
          ReferenceResolver.inheritedHorizontalAlignmentForChildren(
            parentInherited: parent.inheritedHorizontalAlignment,
            ownAlignment: adaptiveMap['horizontalAlignment'] as String?,
          ),
    );

    return ProviderScope(
      overrides: [
        styleReferenceResolverProvider.overrideWithValue(childResolver),
      ],
      child: child,
    );
  }
}
