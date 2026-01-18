import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards/src/generic_action.dart';
import 'package:flutter_adaptive_cards/src/inherited_reference_resolver.dart';

class SeparatorElement extends StatefulWidget
    implements AdaptiveElementWidgetMixin {
  @override
  final Map<String, dynamic> adaptiveMap;

  final Widget child;

  const SeparatorElement({
    super.key,
    required this.adaptiveMap,
    required this.child,
  });

  @override
  SeparatorElementState createState() => SeparatorElementState();
}

class SeparatorElementState extends State<SeparatorElement>
    with AdaptiveElementMixin {
  late double? topSpacing;
  late bool separator;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    topSpacing = InheritedReferenceResolver.of(
      context,
    ).resolver.resolveSpacing(adaptiveMap['spacing']);
    separator = adaptiveMap['separator'] ?? false;
  }

  @override
  Widget build(BuildContext context) {
    if (!separator) {
      return widget.child;
    } else {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Divider(height: topSpacing),
          widget.child,
        ],
      );
    }
  }
}

class AdaptiveTappable extends StatefulWidget with AdaptiveElementWidgetMixin {
  AdaptiveTappable({super.key, required this.child, required this.adaptiveMap});

  final Widget child;

  @override
  final Map<String, dynamic> adaptiveMap;

  @override
  AdaptiveTappableState createState() => AdaptiveTappableState();
}

class AdaptiveTappableState extends State<AdaptiveTappable>
    with AdaptiveElementMixin {
  GenericAction? action;

  @override
  void initState() {
    super.initState();
    if (adaptiveMap.containsKey('selectAction')) {
      action = widgetState.cardRegistry.getGenericAction(
        adaptiveMap['selectAction'],
        widgetState,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(onTap: action?.tap, child: widget.child);
  }
}

/// Used in some containers to change the style from there on down
class ChildStyler extends StatelessWidget {
  final Widget child;

  final Map<String, dynamic> adaptiveMap;

  const ChildStyler({
    super.key,
    required this.child,
    required this.adaptiveMap,
  });

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
