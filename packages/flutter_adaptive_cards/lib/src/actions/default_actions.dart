import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/src/actions/action_handler.dart';
import 'package:flutter_adaptive_cards/src/actions/generic_action.dart';
import 'package:flutter_adaptive_cards/src/adaptive_mixins.dart';
import 'package:flutter_adaptive_cards/src/flutter_raw_adaptive_card.dart';
import 'package:flutter_adaptive_cards/src/riverpod_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:format/format.dart';
import 'package:url_launcher/url_launcher.dart';

/// Default actions for onTaps for Action.Submit
/// Expects there to be supplementary data in 'data' property
class DefaultSubmitAction extends GenericSubmitAction {
  const DefaultSubmitAction();

  @override
  void tap({
    required BuildContext context,
    required RawAdaptiveCardState rawAdaptiveCardState,
    required Map<String, dynamic> adaptiveMap,
  }) {
    bool valid = true;

    // Pull initial submit data from the map
    final Map<String, dynamic> data =
        (adaptiveMap['data'] as Map<String, dynamic>?) != null
        ? Map<String, dynamic>.from(adaptiveMap['data'] as Map)
        : <String, dynamic>{};

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
class DefaultExecuteAction extends GenericExecuteAction {
  const DefaultExecuteAction();

  @override
  void tap({
    required BuildContext context,
    required RawAdaptiveCardState rawAdaptiveCardState,
    required Map<String, dynamic> adaptiveMap,
  }) {
    bool valid = true;

    final Map<String, dynamic> data =
        (adaptiveMap['data'] as Map<String, dynamic>?) != null
        ? Map<String, dynamic>.from(adaptiveMap['data'] as Map)
        : <String, dynamic>{};

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
class DefaultOpenUrlAction extends GenericActionOpenUrl {
  const DefaultOpenUrlAction();

  @override
  void tap({
    required BuildContext context,
    required RawAdaptiveCardState rawAdaptiveCardState,
    required Map<String, dynamic> adaptiveMap,
    String? altUrl,
  }) {
    final String? urlFromMap = adaptiveMap['url'] as String?;
    final String? urlToOpen = altUrl ?? urlFromMap;
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
                urlFromMap ?? '',
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

/// idential to DefaultOpenUrlAction for now
class DefaultOpenUrlDialogAction extends GenericActionOpenUrlDialog {
  const DefaultOpenUrlDialogAction();

  @override
  void tap({
    required BuildContext context,
    required RawAdaptiveCardState rawAdaptiveCardState,
    required Map<String, dynamic> adaptiveMap,
    String? altUrl,
  }) {
    final String? urlFromMap = adaptiveMap['url'] as String?;
    final String? urlToOpen = altUrl ?? urlFromMap;
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
                urlFromMap ?? '',
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

class DefaultResetInputsAction extends GenericActionResetInputs {
  const DefaultResetInputsAction();

  @override
  void tap({
    required BuildContext context,
    required RawAdaptiveCardState rawAdaptiveCardState,
    required Map<String, dynamic> adaptiveMap,
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

class DefaultToggleVisibilityAction extends GenericActionToggleVisibility {
  const DefaultToggleVisibilityAction();

  @override
  void tap({
    required BuildContext context,
    required RawAdaptiveCardState rawAdaptiveCardState,
    required Map<String, dynamic> adaptiveMap,
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
