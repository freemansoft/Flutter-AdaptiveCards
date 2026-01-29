import 'package:flutter_adaptive_cards/src/flutter_raw_adaptive_card.dart';

/// Generic actions forward to the RawAdaptiveCardState
/// functions that are specific to the action type
///
/// The root default beahvior for onTaps in for all actions
/// Each action type has its own implementation
abstract class GenericAction {
  GenericAction(this.adaptiveMap);

  String? get title => adaptiveMap['title'] as String?;
  final Map<String, dynamic> adaptiveMap;

  void tap(RawAdaptiveCardState rawAdaptiveCardState);
}

/// Default actions for onTaps for Action.Submit
/// Delegates to rawAdaptiveCardState
class GenericSubmitAction extends GenericAction {
  GenericSubmitAction({
    required Map<String, dynamic> adaptiveMap,
  }) : super(adaptiveMap) {
    data = adaptiveMap['data'] as Map<String, dynamic>? ?? {};
  }

  late Map<String, dynamic> data;

  @override
  void tap(RawAdaptiveCardState rawAdaptiveCardState) {
    rawAdaptiveCardState.submit(data);
  }
}

/// Default actions for onTaps for Action.Execute
/// Delegates to rawAdaptiveCardState
class GenericExecuteAction extends GenericAction {
  GenericExecuteAction({
    required Map<String, dynamic> adaptiveMap,
  }) : super(adaptiveMap) {
    data = adaptiveMap['data'] as Map<String, dynamic>? ?? {};
  }

  late Map<String, dynamic> data;

  @override
  void tap(RawAdaptiveCardState rawAdaptiveCardState) {
    rawAdaptiveCardState.execute(data);
  }
}

/// Default actions for onTaps for Action.OpenUrl
/// Delegates to rawAdaptiveCardState
class GenericActionOpenUrl extends GenericAction {
  GenericActionOpenUrl({
    required Map<String, dynamic> adaptiveMap,
  }) : super(adaptiveMap) {
    url = adaptiveMap['url'] as String?;
  }

  late String? url;

  @override
  void tap(RawAdaptiveCardState rawAdaptiveCardState) {
    if (url != null) {
      rawAdaptiveCardState.openUrl(url!);
    }
  }
}

class GenericActionResetInputs extends GenericAction {
  GenericActionResetInputs({
    required Map<String, dynamic> adaptiveMap,
  }) : super(adaptiveMap);

  @override
  void tap(RawAdaptiveCardState rawAdaptiveCardState) {
    rawAdaptiveCardState.resetInputs();
  }
}

class GenericActionToggleVisibility extends GenericAction {
  GenericActionToggleVisibility({
    required Map<String, dynamic> adaptiveMap,
  }) : super(adaptiveMap);

  @override
  void tap(RawAdaptiveCardState rawAdaptiveCardState) {
    late List<String> targetElementIds;

    // Toggle visibility for each target element
    // Parse targetElements - can be a list of strings or TargetElement objects
    final targetElements =
        adaptiveMap['targetElements'] as List<dynamic>? ?? [];
    targetElementIds = [];

    for (final element in targetElements) {
      if (element is String) {
        // Simple string ID
        targetElementIds.add(element);
      } else if (element is Map<String, dynamic>) {
        // TargetElement object with elementId property
        final elementId = element['elementId'] as String?;
        if (elementId != null) {
          targetElementIds.add(elementId);
        }
      }
    }
    for (final elementId in targetElementIds) {
      rawAdaptiveCardState.toggleVisibility(id: elementId);
    }
  }
}
