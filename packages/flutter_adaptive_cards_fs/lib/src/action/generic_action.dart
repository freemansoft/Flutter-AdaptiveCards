import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/flutter_raw_adaptive_card.dart';

/// GenericActions are injectible action handlers that
/// the default handlers forward to the RawAdaptiveCardState
/// functions that are specific to the action type
///
/// The root default beahvior for onTaps in each of the Action types
/// Each action type has its own implementation
abstract class const GenericAction() {
  /// Base type for injectable action tap handlers resolved by
  /// `ActionTypeRegistry`.
  this;

  /// Returns the action label from [adaptiveMap], typically the `title`
  /// property.
  String? title(Map<String, dynamic> adaptiveMap) =>
      adaptiveMap['title'] as String?;

  /// Handles a user tap for this action type.
  void tap({
    required BuildContext context,
    required RawAdaptiveCardState rawAdaptiveCardState,
    required Map<String, dynamic> adaptiveMap,
  });
}

/// Abstract action type for Action.Submit
abstract class const GenericSubmitAction() extends GenericAction {
  /// Handler contract for `Action.Submit` taps.
  this;

  @override
  void tap({
    required BuildContext context,
    required RawAdaptiveCardState rawAdaptiveCardState,
    required Map<String, dynamic> adaptiveMap,
  });
}

/// Abstract action type for Action.Execute
abstract class const GenericExecuteAction() extends GenericAction {
  /// Handler contract for `Action.Execute` taps.
  this;

  @override
  void tap({
    required BuildContext context,
    required RawAdaptiveCardState rawAdaptiveCardState,
    required Map<String, dynamic> adaptiveMap,
  });
}

/// Abstract action type for Action.OpenUrl
abstract class const GenericActionOpenUrl() extends GenericAction {
  /// Handler contract for `Action.OpenUrl` taps.
  this;

  @override
  void tap({
    required BuildContext context,
    required RawAdaptiveCardState rawAdaptiveCardState,
    required Map<String, dynamic> adaptiveMap,
    String? altUrl,
  });
}

/// Abstract action for onTaps for Action.OpenUrlDialog
/// Exists to support possible webview in future
abstract class const GenericActionOpenUrlDialog() extends GenericActionOpenUrl {
  /// Handler contract for `Action.OpenUrlDialog` taps.
  this;
}

/// Abstract action for onTaps for Action.ResetInputs
abstract class const GenericActionResetInputs() extends GenericAction {
  /// Handler contract for `Action.ResetInputs` taps.
  this;

  @override
  void tap({
    required BuildContext context,
    required RawAdaptiveCardState rawAdaptiveCardState,
    required Map<String, dynamic> adaptiveMap,
  });
}

/// Handler contract for `Action.ToggleVisibility` taps.
abstract class const GenericActionToggleVisibility() extends GenericAction {
  /// Creates a toggle-visibility action handler implementation.
  this;

  @override
  void tap({
    required BuildContext context,
    required RawAdaptiveCardState rawAdaptiveCardState,
    required Map<String, dynamic> adaptiveMap,
  });
}

/// Handler contract for `Action.Http` taps.
///
/// **Deprecated/legacy:** `Action.Http` was the original Adaptive Cards HTTP
/// action model (schema v1.0), superseded by `Action.Execute` (Universal Action
/// Model, schema v1.4). It is still used by Outlook Actionable Messages.
abstract class const GenericHttpAction() extends GenericAction {
  /// Creates an `Action.Http` handler implementation.
  this;

  @override
  void tap({
    required BuildContext context,
    required RawAdaptiveCardState rawAdaptiveCardState,
    required Map<String, dynamic> adaptiveMap,
  });
}

/// Handler contract for `Action.Popover` taps.
abstract class const GenericPopoverAction() extends GenericAction {
  /// Creates a popover action handler implementation.
  this;

  @override
  void tap({
    required BuildContext context,
    required RawAdaptiveCardState rawAdaptiveCardState,
    required Map<String, dynamic> adaptiveMap,
  });
}
