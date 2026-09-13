import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/models/action_invoke.dart';

/// Host callback bundle for action and input events.
///
/// Wrap your card subtree so [of] resolves handlers for Submit, Execute,
/// OpenUrl, OpenUrlDialog, Refresh, and input [onChange].
class const InheritedAdaptiveCardHandlers({
  super.key,

  /// Called when an Action.Submit is pressed and default action handlers run.
  ///
  /// `invoke.data` contains merged action `data` and input values;
  /// `invoke.actionId` is set when the action JSON defines an author `id`.
  required final void Function(SubmitActionInvoke invoke) onSubmit,

  /// Called when an Action.Execute is pressed and default action handlers run.
  ///
  /// `invoke.data` contains merged action `data` and input values;
  /// `invoke.verb` and `invoke.actionId` come from the action JSON when set.
  required final void Function(ExecuteActionInvoke invoke) onExecute,

  /// Called when an Action.OpenUrl is pressed and default action handlers run.
  ///
  /// `invoke.url` and optional `invoke.actionId` come from the action JSON.
  required final void Function(OpenUrlActionInvoke invoke) onOpenUrl,

  /// Called when an Action.OpenUrlDialog is pressed and default handlers run.
  ///
  /// `invoke.url` and optional `invoke.actionId` come from the action JSON.
  required final void Function(OpenUrlDialogActionInvoke invoke)
  onOpenUrlDialog,

  /// Called when an input value changes (not sourced from an action).
  required final void Function(InputChangeInvoke invoke) onChange,

  /// Called when the root card `refresh` action fires (manual or auto-expire).
  ///
  /// When null, refresh falls back to [onExecute] with the same payload shape.
  final void Function(RefreshActionInvoke invoke)? onRefresh,

  /// Called when an `Action.Http` is pressed and default handlers run.
  ///
  /// **Deprecated/legacy:** `Action.Http` was the original Adaptive Cards HTTP
  /// action model (schema v1.0), superseded by `Action.Execute` (Universal
  /// Action Model, schema v1.4); still used by Outlook Actionable Messages.
  /// `invoke` carries the resolved method/url/headers/body (after
  /// `{{inputId.value}}` substitution) plus the raw input values. When null,
  /// the action does nothing beyond a debug-mode notice; wire a host handler
  /// (for example `flutter_adaptive_cards_host_fs`) to perform the request.
  final void Function(HttpActionInvoke invoke)? onHttp,

  /// Called when a card `authentication` sign-in button is pressed.
  ///
  /// `invoke.value` is the sign-in URL and `invoke.connectionName` is the OAuth
  /// connection. When null, a button with an http(s) `value` falls back to
  /// [onOpenUrl]; a non-URL value is a no-op.
  final void Function(SigninActionInvoke invoke)? onSignin,
  required super.child,
}) extends InheritedWidget {
  /// Creates handlers that descendants resolve via [of].
  ///
  /// Wrap an `AdaptiveCardsCanvas` or `RawAdaptiveCard` subtree so action and
  /// input callbacks are delivered to the host application.
  this;

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
