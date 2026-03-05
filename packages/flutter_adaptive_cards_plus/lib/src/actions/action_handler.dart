import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_plus/src/flutter_raw_adaptive_card.dart';
import 'package:flutter_adaptive_cards_plus/src/models/data_query.dart';

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

  /// called when a Action.Submit submit is pressed
  final Function(Map map) onSubmit;

  /// called when an Action.Execute execute is pressed
  final Function(Map map) onExecute;

  /// called when an Action.OpenUrl openUrl is pressed
  final Function(String url) onOpenUrl;

  /// called when an Action.OpenUrlDialog openUrlDialog is pressed
  final Function(String url) onOpenUrlDialog;

  /// called when a value changes in an Input.ChoiceSet
  final Function(
    String id,
    dynamic value,
    DataQuery? dataQuery,
    RawAdaptiveCardState cardState,
  )
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
