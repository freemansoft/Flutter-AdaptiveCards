import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/src/flutter_raw_adaptive_card.dart';

/// Generic actions forward to the RawAdaptiveCardState
/// functions that are specific to the action type
///
/// The root default beahvior for onTaps in for all actions
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

/// Default actions for onTaps for Action.OpenUrlDialog
/// Exists to support possible webview in future
abstract class GenericActionOpenUrlDialog extends GenericActionOpenUrl {
  const GenericActionOpenUrlDialog();
}

abstract class GenericActionResetInputs extends GenericAction {
  const GenericActionResetInputs();

  @override
  void tap({
    required BuildContext context,
    required RawAdaptiveCardState rawAdaptiveCardState,
    required Map<String, dynamic> adaptiveMap,
  });
}

abstract class GenericActionToggleVisibility extends GenericAction {
  const GenericActionToggleVisibility();

  @override
  void tap({
    required BuildContext context,
    required RawAdaptiveCardState rawAdaptiveCardState,
    required Map<String, dynamic> adaptiveMap,
  });
}
