import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_plus/src/flutter_raw_adaptive_card.dart';

/// Applications could add this above the Adaptive cards tree
///
/// There are tests that auto inject handlers into the widget tree
/// could be useful for validating callbacks.
///
/// Insert one of these in the widget tree to inject
/// onSubmit(), onChange(), onExecute(), and onOpenUrl()
/// handlers outside of the GenericActions framework.
///
/// See DefaultActions as to how this could be used.
///
/// The onChange here gets injected into the [RawAdaptiveCardState] onChange handler
///
/// The handlers here will be attached to widgets in the tree
class InheritedAdaptiveCardHandlers extends InheritedWidget {
  const InheritedAdaptiveCardHandlers({
    super.key,

    required this.onSubmit,
    required this.onExecute,
    required this.onOpenUrl,
    required this.onOpenUrlDialog,

    required this.onChange,
    required super.child,
  });

  final Function(Map map) onSubmit;
  final Function(Map map) onExecute;
  final Function(String url) onOpenUrl;
  final Function(String url) onOpenUrlDialog;

  final Function(String id, dynamic value, RawAdaptiveCardState cardState)?
  onChange;

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
