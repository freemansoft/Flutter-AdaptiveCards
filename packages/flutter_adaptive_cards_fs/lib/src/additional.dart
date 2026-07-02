import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/action/generic_action.dart';
import 'package:flutter_adaptive_cards_fs/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards_fs/src/reference_resolver.dart';
import 'package:flutter_adaptive_cards_fs/src/riverpod/providers.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Additional widget classes used to frame out the rendering of cards
// Not part of the Adaptive-card standard

/// Applies Adaptive Cards spacing and optional separator above child content in
/// custom elements.
class SeparatorElement extends StatelessWidget {
  /// Applies Adaptive Card `spacing` and optional `separator` above [child].
  const SeparatorElement({
    super.key,
    required this.adaptiveMap,
    required this.child,
  });

  /// Element JSON supplying `spacing`, `separator`, and `type`.
  final Map<String, dynamic> adaptiveMap;

  /// Content rendered below the separator or spacing inset.
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

/// Wraps any element subtree to honor JSON `selectAction` taps in custom
/// renderers.
class AdaptiveTappable extends StatefulWidget with AdaptiveElementWidgetMixin {
  /// Wraps [child] with an [InkWell] when [adaptiveMap] defines `selectAction`.
  ///
  /// The wrapper key is deterministic (`{id}_selectAction`) so element reuse
  /// and integration-test lookups are stable across rebuilds. The seed is the
  /// wrapped element's own id via [loadId]; callers whose map has no id (e.g.
  /// table cells, whose `toJson()` omits `type`) must pass [idSeed] with a
  /// stable positional id. See [docs/AdaptiveWidget-Key-Generation.md].
  factory AdaptiveTappable({
    required Widget child,
    required Map<String, dynamic> adaptiveMap,
    String? idSeed,
  }) {
    final String seed = idSeed ?? loadId(adaptiveMap);
    return AdaptiveTappable._(
      adaptiveMap: adaptiveMap,
      id: seed,
      key: generateWidgetKeyFromId(seed, suffix: 'selectAction'),
      child: child,
    );
  }

  AdaptiveTappable._({
    super.key,
    required this.adaptiveMap,
    required this.id,
    required this.child,
  });

  /// Visual content that receives the optional tap target.
  final Widget child;

  @override
  final Map<String, dynamic> adaptiveMap;

  /// Auto-generated id for tap wrapper widgets without author `id`.
  @override
  final String id;

  @override
  AdaptiveTappableState createState() => AdaptiveTappableState();
}

/// State for [AdaptiveTappable] that resolves and invokes `selectAction`.
class AdaptiveTappableState extends State<AdaptiveTappable>
    with AdaptiveElementMixin, ProviderScopeMixin {
  /// Resolved handler for `selectAction`, if present in [adaptiveMap].
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

/// Pushes container `style` and `horizontalAlignment` inheritance to
/// descendants via scoped resolver.
class ChildStyler extends StatelessWidget {
  /// Pushes container style and alignment context to [child] via a scoped
  /// resolver.
  const ChildStyler({
    super.key,
    required this.child,
    required this.adaptiveMap,
  });

  /// Descendant subtree that inherits the updated [ReferenceResolver].
  final Widget child;

  /// Container JSON whose `style` and `horizontalAlignment` update inheritance.
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
