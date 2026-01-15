import 'package:flutter_adaptive_cards/src/flutter_raw_adaptive_card.dart';

/// The root default actions for onTaps for Action.Submit and Action.OpenUrl
abstract class GenericAction {
  GenericAction(this.adaptiveMap, this.rawAdaptiveCardState);

  String? get title => adaptiveMap['title'];
  final Map<String, dynamic> adaptiveMap;
  final RawAdaptiveCardState rawAdaptiveCardState;

  void tap();
}

/// Default actions for onTaps for Action.Submit
/// Delegates to rawAdaptiveCardState
class GenericSubmitAction extends GenericAction {
  GenericSubmitAction(
    Map<String, dynamic> adaptiveMap,
    RawAdaptiveCardState rawAdaptiveCardState,
  ) : super(adaptiveMap, rawAdaptiveCardState) {
    data = adaptiveMap['data'] ?? {};
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
  GenericExecuteAction(
    Map<String, dynamic> adaptiveMap,
    RawAdaptiveCardState rawAdaptiveCardState,
  ) : super(adaptiveMap, rawAdaptiveCardState) {
    data = adaptiveMap['data'] ?? {};
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
  GenericActionOpenUrl(
    Map<String, dynamic> adaptiveMap,
    RawAdaptiveCardState rawAdaptiveCardState,
  ) : super(adaptiveMap, rawAdaptiveCardState) {
    url = adaptiveMap['url'];
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
  GenericActionResetInputs(
    super.adaptiveMap,
    super.rawAdaptiveCardState,
  );

  @override
  void tap() {
    rawAdaptiveCardState.resetInputs();
  }
}
