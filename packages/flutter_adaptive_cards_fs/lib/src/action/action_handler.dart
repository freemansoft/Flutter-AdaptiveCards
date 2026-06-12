import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/models/action_invoke.dart';

/// Host callback bundle for action and input events.
///
/// Wrap your card subtree so [of] resolves handlers for Submit, Execute,
/// OpenUrl, OpenUrlDialog, Refresh, and input [onChange].
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

  /// Lookup for host callbacks installed above the card.
  ///
  /// Returns `null` when the subtree is not wrapped.
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
