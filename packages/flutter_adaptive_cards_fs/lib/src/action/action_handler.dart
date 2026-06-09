import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/models/action_invoke.dart';

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
/// The onChange here is a little different. It isn't sourced from an Action
/// but rather from the Input widgets themselves.
/// It is injected into the `RawAdaptiveCard` onChange handler
///
/// The handlers here will be attached to widgets in the tree
class InheritedAdaptiveCardHandlers extends InheritedWidget {
  /// Creates handlers that descendants resolve via [of].
  ///
  /// Wrap an `AdaptiveCardsCanvas` or `RawAdaptiveCard` subtree so action and
  /// input callbacks are delivered to the host application.
  const InheritedAdaptiveCardHandlers({
    super.key,

    required this.onSubmit,
    required this.onExecute,
    required this.onOpenUrl,
    required this.onOpenUrlDialog,

    required this.onChange,
    this.onRefresh,
    required super.child,
  });

  /// Called when an Action.Submit is pressed and default action handlers run.
  ///
  /// `invoke.data` contains merged action `data` and input values;
  /// `invoke.actionId` is set when the action JSON defines an author `id`.
  final void Function(SubmitActionInvoke invoke) onSubmit;

  /// Called when an Action.Execute is pressed and default action handlers run.
  ///
  /// `invoke.data` contains merged action `data` and input values;
  /// `invoke.verb` and `invoke.actionId` come from the action JSON when set.
  final void Function(ExecuteActionInvoke invoke) onExecute;

  /// Called when an Action.OpenUrl is pressed and default action handlers run.
  ///
  /// `invoke.url` and optional `invoke.actionId` come from the action JSON.
  final void Function(OpenUrlActionInvoke invoke) onOpenUrl;

  /// Called when an Action.OpenUrlDialog is pressed and default handlers run.
  ///
  /// `invoke.url` and optional `invoke.actionId` come from the action JSON.
  final void Function(OpenUrlDialogActionInvoke invoke) onOpenUrlDialog;

  /// Called when an input value changes (not sourced from an action).
  final void Function(InputChangeInvoke invoke) onChange;

  /// Called when the root card `refresh` action fires (manual or auto-expire).
  ///
  /// When null, refresh falls back to [onExecute] with the same payload shape.
  final void Function(RefreshActionInvoke invoke)? onRefresh;

  /// Returns the nearest ancestor handlers, or `null` when none are installed.
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
