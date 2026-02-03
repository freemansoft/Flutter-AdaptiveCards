import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/src/actions/generic_action.dart';
import 'package:flutter_adaptive_cards/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards/src/hostconfig/miscellaneous_configs.dart';
import 'package:flutter_adaptive_cards/src/riverpod_providers.dart';
import 'package:flutter_adaptive_cards/src/utils/utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    final topSpacing = SpacingsConfig.resolveSpacing(
      ProviderScope.containerOf(
        context,
      ).read(styleReferenceResolverProvider).getSpacingsConfig(),
      adaptiveMap['spacing'],
    );

    final separator = adaptiveMap['separator'] as bool? ?? false;
    if (!separator) {
      if (adaptiveMap['type']?.toString().toLowerCase() == 'column') {
        return Container(
          padding: EdgeInsets.only(left: topSpacing),
          child: child,
        );
      } else {
        return Container(
          padding: EdgeInsets.only(top: topSpacing),
          child: child,
        );
      }
    } else {
      final resolver = ProviderScope.containerOf(
        context,
      ).read(styleReferenceResolverProvider);
      final color = resolver.resolveSeparatorColor();
      final thickness = resolver.resolveSeparatorThickness();

      // TODO(username): This should actually be done in the ColumnSet
      if (adaptiveMap['type']?.toString().toLowerCase() == 'column') {
        // The divider isn't showing :-( Why?
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            VerticalDivider(
              width: topSpacing,
              thickness: thickness,
              color: color,
            ),
            Expanded(child: child),
          ],
        );
      } else {
        return Column(
          mainAxisSize: MainAxisSize.min,
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
/// Used in Image, Container, Column, columnSet, adaptiveCard, etc.
class AdaptiveTappable extends StatefulWidget with AdaptiveElementWidgetMixin {
  AdaptiveTappable({
    required this.child,
    required this.adaptiveMap,
  }) : super(key: generateAdaptiveWidgetKey(adaptiveMap)) {
    id = loadId(adaptiveMap);
  }

  final Widget child;

  @override
  final Map<String, dynamic> adaptiveMap;

  @override
  late final String id;

  @override
  AdaptiveTappableState createState() => AdaptiveTappableState();

  /// Tappable is an element because of some context required
  /// But it really isn't something we operate against so we just generate an id
  /// Should get picked up even though we import utils.
  String loadId(Map aMap) {
    return UUIDGenerator().getId();
  }
}

class AdaptiveTappableState extends State<AdaptiveTappable>
    with AdaptiveElementMixin {
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
    // TODO(username): implement style changing logic for inheriting parent style
    return child;
  }
}
