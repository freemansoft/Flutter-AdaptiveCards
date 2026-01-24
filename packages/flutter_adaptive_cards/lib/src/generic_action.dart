import 'package:flutter_adaptive_cards/src/flutter_raw_adaptive_card.dart';

/// Generic actions forward to the RawAdaptiveCardState
/// functions that are specific to the action type
///
/// The root default beahvior for onTaps in for all actions
/// Each action type has its own implementation
abstract class GenericAction {
  GenericAction(this.adaptiveMap, this.rawAdaptiveCardState);

  String? get title => adaptiveMap['title'] as String?;
  final Map<String, dynamic> adaptiveMap;
  final RawAdaptiveCardState rawAdaptiveCardState;

  void tap();
}

/// Default actions for onTaps for Action.Submit
/// Delegates to rawAdaptiveCardState
class GenericSubmitAction extends GenericAction {
  GenericSubmitAction({
    required Map<String, dynamic> adaptiveMap,
    required RawAdaptiveCardState rawAdaptiveCardState,
  }) : super(adaptiveMap, rawAdaptiveCardState) {
    data = adaptiveMap['data'] as Map<String, dynamic>? ?? {};
  }

  late Map<String, dynamic> data;

  @override
  void tap() {
    rawAdaptiveCardState.submit(data);
  }
}

/// Default actions for onTaps for Action.Execute
/// Delegates to rawAdaptiveCardState
class GenericExecuteAction extends GenericAction {
  GenericExecuteAction({
    required Map<String, dynamic> adaptiveMap,
    required RawAdaptiveCardState rawAdaptiveCardState,
  }) : super(adaptiveMap, rawAdaptiveCardState) {
    data = adaptiveMap['data'] as Map<String, dynamic>? ?? {};
  }

  late Map<String, dynamic> data;

  @override
  void tap() {
    rawAdaptiveCardState.execute(data);
  }
}

/// Default actions for onTaps for Action.OpenUrl
/// Delegates to rawAdaptiveCardState
class GenericActionOpenUrl extends GenericAction {
  GenericActionOpenUrl({
    required Map<String, dynamic> adaptiveMap,
    required RawAdaptiveCardState rawAdaptiveCardState,
  }) : super(adaptiveMap, rawAdaptiveCardState) {
    url = adaptiveMap['url'] as String?;
  }

  late String? url;

  @override
  void tap() {
    if (url != null) {
      rawAdaptiveCardState.openUrl(url!);
    }
  }
}

class GenericActionResetInputs extends GenericAction {
  GenericActionResetInputs({
    required Map<String, dynamic> adaptiveMap,
    required RawAdaptiveCardState rawAdaptiveCardState,
  }) : super(adaptiveMap, rawAdaptiveCardState);

  @override
  void tap() {
    rawAdaptiveCardState.resetInputs();
  }
}
