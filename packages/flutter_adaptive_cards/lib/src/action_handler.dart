import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/src/flutter_raw_adaptive_card.dart';

/// Insert one of these in the widget tree to inject onSubmit(), onChange(), onExecute(), and onOpenUrl() handlers
/// The handlers here will be attached to widgets in the tree
class InheritedAdaptiveCardHandlers extends InheritedWidget {
  const InheritedAdaptiveCardHandlers({
    super.key,
    required this.onSubmit,
    required this.onExecute,
    required this.onOpenUrl,
    required this.onChange,
    required super.child,
  });

  final Function(Map map) onSubmit;
  final Function(Map map) onExecute;
  final Function(String id, dynamic value, RawAdaptiveCardState cardState)?
  onChange;
  final Function(String url) onOpenUrl;

  static InheritedAdaptiveCardHandlers? of(BuildContext context) {
    final InheritedAdaptiveCardHandlers? handlers = context
        .dependOnInheritedWidgetOfExactType<InheritedAdaptiveCardHandlers>();
    if (handlers == null) return null;
    return handlers;
  }

  @override
  bool updateShouldNotify(InheritedAdaptiveCardHandlers oldWidget) =>
      oldWidget != this;
}
