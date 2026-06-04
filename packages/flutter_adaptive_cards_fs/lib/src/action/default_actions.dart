import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/action/action_handler.dart';
import 'package:flutter_adaptive_cards_fs/src/action/generic_action.dart';
import 'package:flutter_adaptive_cards_fs/src/flutter_raw_adaptive_card.dart';
import 'package:flutter_adaptive_cards_fs/src/riverpod/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
// Default action handlers with basic behavior
// including forwarding to the InheritedAdaptiveCardHandlers

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
    // Pull initial submit data from the map
    final Map<String, dynamic> data =
        (adaptiveMap['data'] as Map<String, dynamic>?) != null
        ? Map<String, dynamic>.from(adaptiveMap['data'] as Map)
        : <String, dynamic>{};

    final container = ProviderScope.containerOf(context);
    final doc = container.read(adaptiveCardDocumentProvider);
    final values = container
        .read(adaptiveCardDocumentProvider.notifier)
        .collectInputValues();

    var valid = true;
    for (final entry in doc.nodesById.entries) {
      final node = entry.value;
      final type = node['type'] as String?;
      if (type == null || !type.startsWith('Input.')) continue;
      final resolved = container.read(resolvedElementProvider(entry.key));
      final isRequired = resolved?['isRequired'] as bool? ?? false;
      if (!isRequired) continue;
      final value = values[entry.key];
      if (value == null) {
        valid = false;
        break;
      }
      if (value is String && value.isEmpty) {
        valid = false;
        break;
      }
    }

    data.addAll(values);

    if (!valid) return;

    final foo = InheritedAdaptiveCardHandlers.of(context);
    if (foo != null) {
      foo.onSubmit(data);
    } else if (kDebugMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No custom handler found for onSubmit: \n $data',
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
    String? verb, // added in schema 1.6
  }) {
    final Map<String, dynamic> data =
        (adaptiveMap['data'] as Map<String, dynamic>?) != null
        ? Map<String, dynamic>.from(adaptiveMap['data'] as Map)
        : <String, dynamic>{};

    final container = ProviderScope.containerOf(context);
    final doc = container.read(adaptiveCardDocumentProvider);
    final values = container
        .read(adaptiveCardDocumentProvider.notifier)
        .collectInputValues();

    var valid = true;
    for (final entry in doc.nodesById.entries) {
      final node = entry.value;
      final type = node['type'] as String?;
      if (type == null || !type.startsWith('Input.')) continue;
      final resolved = container.read(resolvedElementProvider(entry.key));
      final isRequired = resolved?['isRequired'] as bool? ?? false;
      if (!isRequired) continue;
      final value = values[entry.key];
      if (value == null) {
        valid = false;
        break;
      }
      if (value is String && value.isEmpty) {
        valid = false;
        break;
      }
    }

    data.addAll(values);
    if (!valid) return;

    final foo = InheritedAdaptiveCardHandlers.of(context);
    if (foo != null) {
      foo.onExecute(data);
    } else if (kDebugMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No custom handler found for onExecute: verb: $verb \n $data',
          ),
        ),
      );
    }
  }
}

/// Default actions for onTaps for Action.OpenUrl
///
/// Default behavior is to open the url in a webview
/// limited set of protocols are supported
/// https://www.iana.org/assignments/uri-schemes/uri-schemes.xhtml
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
        if (kDebugMode) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'No custom handler found for onOpenUrl: \n $urlFromMap $altUrl $urlToOpen',
              ),
            ),
          );
        }
        // probably should log that there is no valid url
      }
    }
  }
}

/// Default actions for onTaps for Action.OpenUrlDialog
///
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
        foo.onOpenUrlDialog(urlToOpen);
      } else {
        unawaited(launchUrl(Uri.parse(urlToOpen)));
        if (kDebugMode) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'No custom handler found for onOpenUrlDialog: \n $urlFromMap $altUrl $urlToOpen',
              ),
            ),
          );
        }
        // probably should log that there is no valid url
      }
    }
  }
}

/// Default actions for Action.ResetInputs
/// Resets the form
class DefaultResetInputsAction extends GenericActionResetInputs {
  const DefaultResetInputsAction();

  @override
  void tap({
    required BuildContext context,
    required RawAdaptiveCardState rawAdaptiveCardState,
    required Map<String, dynamic> adaptiveMap,
  }) {
    final container = ProviderScope.containerOf(context);
    container.read(adaptiveCardDocumentProvider.notifier).resetAllInputs();
  }
}

/// Default actions for Action.ToggleVisibility
///
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
      final container = ProviderScope.containerOf(context);
      container
          .read(adaptiveCardDocumentProvider.notifier)
          .toggleVisibility(
            elementId,
          );
    }
  }
}
