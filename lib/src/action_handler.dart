import 'package:flutter/material.dart';

/// Insert one of these in the widget tree to inject onSubmit() an onOpenUrl() handlers
/// The handlers here will be attached to widgets in the tree
class DefaultAdaptiveCardHandlers extends InheritedWidget {
  DefaultAdaptiveCardHandlers({
    super.key,
    required this.onSubmit,
    required this.onOpenUrl,
    required Widget child,
  }) : super(child: child);

  final Function(Map map) onSubmit;
  final Function(String url) onOpenUrl;

  static DefaultAdaptiveCardHandlers? of(BuildContext context) {
    DefaultAdaptiveCardHandlers? handlers = context
        .dependOnInheritedWidgetOfExactType<DefaultAdaptiveCardHandlers>();
    if (handlers == null) return null;
    return handlers;
  }

  @override
  bool updateShouldNotify(DefaultAdaptiveCardHandlers oldWidget) =>
      oldWidget != this;
}
