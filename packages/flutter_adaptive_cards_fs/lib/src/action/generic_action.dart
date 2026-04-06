import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/flutter_raw_adaptive_card.dart';

/// GenericActions are injectible action handlers that
/// the default handlers forward to the RawAdaptiveCardState
/// functions that are specific to the action type
///
/// The root default beahvior for onTaps in each of the Action types
/// Each action type has its own implementation
abstract class GenericAction {
  const GenericAction();

  String? title(Map<String, dynamic> adaptiveMap) =>
      adaptiveMap['title'] as String?;

  void tap({
    required BuildContext context,
    required RawAdaptiveCardState rawAdaptiveCardState,
    required Map<String, dynamic> adaptiveMap,
  });
}

/// Abstract action type for Action.Submit
abstract class GenericSubmitAction extends GenericAction {
  const GenericSubmitAction();

  @override
  void tap({
    required BuildContext context,
    required RawAdaptiveCardState rawAdaptiveCardState,
    required Map<String, dynamic> adaptiveMap,
  });
}

/// Abstract action type for Action.Execute
abstract class GenericExecuteAction extends GenericAction {
  const GenericExecuteAction();

  @override
  void tap({
    required BuildContext context,
    required RawAdaptiveCardState rawAdaptiveCardState,
    required Map<String, dynamic> adaptiveMap,
    String? verb, // added in schema 1.6
  });
}

/// Abstract action type for Action.OpenUrl
abstract class GenericActionOpenUrl extends GenericAction {
  const GenericActionOpenUrl();

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
abstract class GenericActionOpenUrlDialog extends GenericActionOpenUrl {
  const GenericActionOpenUrlDialog();
}

/// Abstract action for onTaps for Action.ResetInputs
abstract class GenericActionResetInputs extends GenericAction {
  const GenericActionResetInputs();

  @override
  void tap({
    required BuildContext context,
    required RawAdaptiveCardState rawAdaptiveCardState,
    required Map<String, dynamic> adaptiveMap,
  });
}

// Abstract action for Action.ToggleVisibility
abstract class GenericActionToggleVisibility extends GenericAction {
  const GenericActionToggleVisibility();

  @override
  void tap({
    required BuildContext context,
    required RawAdaptiveCardState rawAdaptiveCardState,
    required Map<String, dynamic> adaptiveMap,
  });
}
