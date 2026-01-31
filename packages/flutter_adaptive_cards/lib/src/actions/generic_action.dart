import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/src/actions/action_handler.dart';
import 'package:flutter_adaptive_cards/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards/src/flutter_raw_adaptive_card.dart';
import 'package:flutter_adaptive_cards/src/riverpod_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:format/format.dart';
import 'package:url_launcher/url_launcher.dart';

/// Generic actions forward to the RawAdaptiveCardState
/// functions that are specific to the action type
///
/// The root default beahvior for onTaps in for all actions
/// Each action type has its own implementation
abstract class GenericAction {
  GenericAction(this.adaptiveMap);

  String? get title => adaptiveMap['title'] as String?;
  final Map<String, dynamic> adaptiveMap;

  void tap({
    required BuildContext context,
    required RawAdaptiveCardState rawAdaptiveCardState,
  });
}

/// Default actions for onTaps for Action.Submit
/// Expects there to be supplementary data in 'data' property
class GenericSubmitAction extends GenericAction {
  GenericSubmitAction({
    required Map<String, dynamic> adaptiveMap,
  }) : super(adaptiveMap) {
    data = adaptiveMap['data'] as Map<String, dynamic>? ?? {};
  }

  /// We should copy this data before modifying it
  late Map<String, dynamic> data;

  @override
  void tap({
    required BuildContext context,
    required RawAdaptiveCardState rawAdaptiveCardState,
  }) {
    bool valid = true;

    // Recursively visits all inputs and determines if all the inputs are valid
    void visitor(Element element) {
      if (element is StatefulElement) {
        if (element.state is AdaptiveInputMixin) {
          if ((element.state as AdaptiveInputMixin).checkRequired()) {
            (element.state as AdaptiveInputMixin).appendInput(data);
          } else {
            valid = false;
          }
        }
      }
      element.visitChildren(visitor);
    }

    // We need the context of the nearest ancestor AdaptiveCardElement
    ProviderScope.containerOf(
          context,
        )
        .read(adaptiveCardElementStateProvider)
        .context
        .visitChildElements(visitor);
    //context.visitChildElements(visitor);

    if (valid) {
      final foo = InheritedAdaptiveCardHandlers.of(context);
      foo != null
          ? foo.onSubmit(data)
          : ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  format(
                    'No custom handler found for onSubmit: \n {}',
                    data.toString(),
                  ),
                ),
              ),
            );
    }
  }
}

/// Default actions for onTaps for Action.Execute
/// Expects there to be supplementary data in 'data' property
class GenericExecuteAction extends GenericAction {
  GenericExecuteAction({
    required Map<String, dynamic> adaptiveMap,
  }) : super(adaptiveMap) {
    data = adaptiveMap['data'] as Map<String, dynamic>? ?? {};
  }

  /// We should copy this data before modifying it
  late Map<String, dynamic> data;

  @override
  void tap({
    required BuildContext context,
    required RawAdaptiveCardState rawAdaptiveCardState,
  }) {
    bool valid = true;

    // Recursively visits all inputs and determines if all the inputs are valid
    void visitor(Element element) {
      if (element is StatefulElement) {
        if (element.state is AdaptiveInputMixin) {
          if ((element.state as AdaptiveInputMixin).checkRequired()) {
            (element.state as AdaptiveInputMixin).appendInput(data);
          } else {
            valid = false;
          }
        }
      }
      element.visitChildren(visitor);
    }

    // We need the context of the nearest ancestor AdaptiveCardElement
    ProviderScope.containerOf(
          context,
        )
        .read(adaptiveCardElementStateProvider)
        .context
        .visitChildElements(visitor);
    //context.visitChildElements(visitor);

    if (valid) {
      final foo = InheritedAdaptiveCardHandlers.of(context);
      foo != null
          ? foo.onExecute(data)
          : ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  format(
                    'No custom handler found for onExecute: \n {}',
                    data.toString(),
                  ),
                ),
              ),
            );
    }
  }
}

/// Default actions for onTaps for Action.OpenUrl
/// Delegates to rawAdaptiveCardState
/// Assumes url is provided in the adaptiveMap
/// Can be overridden by altUrl in tap() - little ugly
class GenericActionOpenUrl extends GenericAction {
  GenericActionOpenUrl({
    required Map<String, dynamic> adaptiveMap,
  }) : super(adaptiveMap) {
    url = adaptiveMap['url'] as String?;
  }

  late String? url;

  @override
  void tap({
    required BuildContext context,
    required RawAdaptiveCardState rawAdaptiveCardState,
    String? altUrl,
  }) {
    final String? urlToOpen = altUrl ?? url;
    if (urlToOpen != null) {
      final foo = InheritedAdaptiveCardHandlers.of(context);
      if (foo != null) {
        foo.onOpenUrl(urlToOpen);
      } else {
        unawaited(launchUrl(Uri.parse(urlToOpen)));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              format(
                'No custom handler found for onOpenUrl: \n {} {} {}',
                url ?? '',
                altUrl ?? '',
                urlToOpen,
              ),
            ),
          ),
        );
        // probably should log that there is no valid url
      }
    }
  }
}

/// Default actions for onTaps for Action.OpenUrlDialog
/// Exists to support possible webview in future
class GenericActionOpenUrlDialog extends GenericActionOpenUrl {
  GenericActionOpenUrlDialog({
    required super.adaptiveMap,
  });
}

class GenericActionResetInputs extends GenericAction {
  GenericActionResetInputs({
    required Map<String, dynamic> adaptiveMap,
  }) : super(adaptiveMap);

  @override
  void tap({
    required BuildContext context,
    required RawAdaptiveCardState rawAdaptiveCardState,
  }) {
    void visitor(Element element) {
      if (element is StatefulElement) {
        if (element.state is AdaptiveInputMixin) {
          (element.state as AdaptiveInputMixin).resetInput();
        }
      }
      element.visitChildren(visitor);
    }

    // We need the context of the nearest ancestor AdaptiveCardElement
    ProviderScope.containerOf(
          context,
        )
        .read(adaptiveCardElementStateProvider)
        .context
        .visitChildElements(visitor);
    //context.visitChildElements(visitor);
  }
}

class GenericActionToggleVisibility extends GenericAction {
  GenericActionToggleVisibility({
    required Map<String, dynamic> adaptiveMap,
  }) : super(adaptiveMap);

  @override
  void tap({
    required BuildContext context,
    required RawAdaptiveCardState rawAdaptiveCardState,
  }) {
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
