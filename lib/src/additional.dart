import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/src/inherited_reference_resolver.dart';

import 'adaptive_mixins.dart';
import 'generic_action.dart';

class SeparatorElement extends StatefulWidget with AdaptiveElementWidgetMixin {
  final Map<String, dynamic> adaptiveMap;
  final Widget child;

  SeparatorElement({super.key, required this.adaptiveMap, required this.child});

  @override
  _SeparatorElementState createState() => _SeparatorElementState();
}

class _SeparatorElementState extends State<SeparatorElement>
    with AdaptiveElementMixin {
  late double? topSpacing;
  late bool separator;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    topSpacing = InheritedReferenceResolver.of(context)
        .resolver
        .resolveSpacing(adaptiveMap['spacing']);
    separator = adaptiveMap['separator'] ?? false;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        separator ? Divider(height: topSpacing) : SizedBox(height: topSpacing),
        widget.child,
      ],
    );
  }
}

class AdaptiveTappable extends StatefulWidget with AdaptiveElementWidgetMixin {
  AdaptiveTappable({super.key, required this.child, required this.adaptiveMap});

  final Widget child;

  final Map<String, dynamic> adaptiveMap;

  @override
  _AdaptiveTappableState createState() => _AdaptiveTappableState();
}

class _AdaptiveTappableState extends State<AdaptiveTappable>
    with AdaptiveElementMixin {
  GenericAction? action;

  @override
  void initState() {
    super.initState();
    if (adaptiveMap.containsKey('selectAction')) {
      action = widgetState.cardRegistry
          .getGenericAction(adaptiveMap['selectAction'], widgetState);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: action?.tap,
      child: widget.child,
    );
  }
}

/// Used in some containers to change the style from there on down
class ChildStyler extends StatelessWidget {
  final Widget child;

  final Map<String, dynamic> adaptiveMap;

  const ChildStyler(
      {super.key, required this.child, required this.adaptiveMap});

  @override
  Widget build(BuildContext context) {
    return InheritedReferenceResolver(
      resolver: InheritedReferenceResolver.of(context)
          .resolver
          .copyWith(style: adaptiveMap['style']),
      child: child,
    );
  }
}
