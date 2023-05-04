import 'package:flutter/material.dart';

import '../flutter_adaptive_cards.dart';
import 'base.dart';
import 'package:provider/provider.dart';

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
    topSpacing = resolver.resolveSpacing(adaptiveMap['spacing']);
    separator = adaptiveMap['separator'] ?? false;
  }

  @override
  Widget build(BuildContext context) {
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

class ChildStyler extends StatelessWidget {
  final Widget child;

  final Map<String, dynamic> adaptiveMap;

  const ChildStyler(
      {super.key, required this.child, required this.adaptiveMap});

  @override
  Widget build(BuildContext context) {
    return InheritedReferenceResolver(
      resolver: context
          .watch<ReferenceResolver>()
          .copyWith(style: adaptiveMap['style']),
      child: child,
    );
  }
}
