import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards/src/flutter_raw_adaptive_card.dart';
import 'package:flutter_adaptive_cards/src/generic_action.dart';
import 'package:flutter_adaptive_cards/src/hostconfig/miscellaneous_configs.dart';
import 'package:flutter_adaptive_cards/src/inherited_reference_resolver.dart';
import 'package:flutter_adaptive_cards/src/utils/utils.dart';

class SeparatorElement extends StatelessWidget {
  const SeparatorElement({
    super.key,
    required this.adaptiveMap,
    required this.widgetState,
    required this.child,
  });

  final Map<String, dynamic> adaptiveMap;

  final RawAdaptiveCardState widgetState;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final topSpacing = SpacingsConfig.resolveSpacing(
      InheritedReferenceResolver.of(
        context,
      ).resolver.getSpacingsConfig(),
      adaptiveMap['spacing'],
    );

    final separator = adaptiveMap['separator'] as bool? ?? false;
    if (!separator) {
      return Container(
        padding: EdgeInsets.only(top: topSpacing),
        child: child,
      );
    } else {
      final resolver = InheritedReferenceResolver.of(context).resolver;
      final separatorConfig = resolver.getSeparatorConfig();
      final color = parseHexColor(separatorConfig?.lineColor);

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Divider(
            height: topSpacing,
            thickness: separatorConfig?.lineThickness.toDouble(),
            color: color,
          ),
          child,
        ],
      );
    }
  }
}

class AdaptiveTappable extends StatefulWidget with AdaptiveElementWidgetMixin {
  AdaptiveTappable({
    super.key,
    required this.child,
    required this.adaptiveMap,
    required this.widgetState,
  });

  final Widget child;

  @override
  final Map<String, dynamic> adaptiveMap;

  @override
  final RawAdaptiveCardState widgetState;

  @override
  AdaptiveTappableState createState() => AdaptiveTappableState();
}

class AdaptiveTappableState extends State<AdaptiveTappable>
    with AdaptiveElementMixin {
  GenericAction? action;

  @override
  void initState() {
    super.initState();
    // The selectAction could be anyone of the action types
    if (adaptiveMap.containsKey('selectAction')) {
      action = widgetState.cardRegistry.getGenericAction(
        map: adaptiveMap['selectAction'],
        state: widgetState,
      );
    }
  }

  /// Tappable is an element because of some context required
  /// But it really isn't something we operate against so we just generate an id
  @override
  String loadId() {
    return UUIDGenerator().getId();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(onTap: action?.tap, child: widget.child);
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
    return InheritedReferenceResolver(
      resolver: InheritedReferenceResolver.of(
        context,
      ).resolver.copyWith(style: adaptiveMap['style']),
      child: child,
    );
  }
}
