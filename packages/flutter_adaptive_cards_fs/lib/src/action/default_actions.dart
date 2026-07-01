import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/action/action_handler.dart';
import 'package:flutter_adaptive_cards_fs/src/action/generic_action.dart';
import 'package:flutter_adaptive_cards_fs/src/action/open_url_dialog_executor.dart';
import 'package:flutter_adaptive_cards_fs/src/action/reset_inputs_executor.dart';
import 'package:flutter_adaptive_cards_fs/src/cards/actions/popover_container.dart';
import 'package:flutter_adaptive_cards_fs/src/cards/inputs/input_range_validation.dart';
import 'package:flutter_adaptive_cards_fs/src/cards/inputs/input_text_validation.dart';
import 'package:flutter_adaptive_cards_fs/src/flutter_raw_adaptive_card.dart';
import 'package:flutter_adaptive_cards_fs/src/models/action_invoke.dart';
import 'package:flutter_adaptive_cards_fs/src/riverpod/providers.dart';
import 'package:flutter_adaptive_cards_fs/src/security/adaptive_uri_validation.dart';
import 'package:flutter_adaptive_cards_fs/src/security/inherited_security_policy.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/associated_inputs.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
// Default action handlers with basic behavior
// including forwarding to the InheritedAdaptiveCardHandlers

/// Returns `false` when any input fails validation and marks each failing
/// input invalid via the document notifier.
bool validateInputs(ProviderContainer container) {
  final doc = container.read(adaptiveCardDocumentProvider);
  final values = container
      .read(adaptiveCardDocumentProvider.notifier)
      .collectInputValues();
  final notifier = container.read(adaptiveCardDocumentProvider.notifier);

  var valid = true;
  for (final entry in doc.nodesById.entries) {
    final node = entry.value;
    final type = node['type'] as String?;
    if (type == null || !type.startsWith('Input.')) continue;
    final resolved = container.read(resolvedElementProvider(entry.key));
    final isRequired = resolved?['isRequired'] as bool? ?? false;
    final value = values[entry.key];

    if (type == 'Input.Text') {
      final regexPattern = node['regex'] as String?;
      if (!textInputValueIsValid(
        value: value?.toString(),
        isRequired: isRequired,
        regexPattern: regexPattern,
      )) {
        valid = false;
        notifier.setInputError(entry.key, isInvalid: true);
      }
      continue;
    }

    if (type == 'Input.Number') {
      // node['min'/'max'] are num in dart:convert-decoded JSON, but guard
      // against string-encoded bounds from template expansion or loose typing.
      final numMin = node['min'] is num
          ? node['min'] as num
          : num.tryParse(node['min']?.toString() ?? '');
      final numMax = node['max'] is num
          ? node['max'] as num
          : num.tryParse(node['max']?.toString() ?? '');
      if (!numberInputValueIsValid(
        value: value?.toString(),
        isRequired: isRequired,
        min: numMin,
        max: numMax,
      )) {
        valid = false;
        notifier.setInputError(entry.key, isInvalid: true);
      }
      continue;
    }

    if (type == 'Input.Date') {
      if (!dateInputValueIsValid(
        value: value?.toString(),
        isRequired: isRequired,
        min: node['min'] as String?,
        max: node['max'] as String?,
      )) {
        valid = false;
        notifier.setInputError(entry.key, isInvalid: true);
      }
      continue;
    }

    if (type == 'Input.Time') {
      if (!timeInputValueIsValid(
        value: value?.toString(),
        isRequired: isRequired,
        min: node['min'] as String?,
        max: node['max'] as String?,
      )) {
        valid = false;
        notifier.setInputError(entry.key, isInvalid: true);
      }
      continue;
    }

    if (!isRequired) continue;
    if (value == null) {
      valid = false;
      notifier.setInputError(entry.key, isInvalid: true);
      continue;
    }
    if (value is String && value.isEmpty) {
      valid = false;
      notifier.setInputError(entry.key, isInvalid: true);
    }
  }
  return valid;
}

/// Default actions for onTaps for Action.Submit
/// Expects there to be supplementary data in 'data' property
class DefaultSubmitAction extends GenericSubmitAction {
  /// Validates inputs, merges `data`, and forwards to
  /// [InheritedAdaptiveCardHandlers.onSubmit].
  const DefaultSubmitAction();

  @override
  void tap({
    required BuildContext context,
    required RawAdaptiveCardState rawAdaptiveCardState,
    required Map<String, dynamic> adaptiveMap,
  }) {
    final container = ProviderScope.containerOf(context);
    final values = container
        .read(adaptiveCardDocumentProvider.notifier)
        .collectInputValues();

    final data = mergeActionData(
      actionData: (adaptiveMap['data'] as Map<String, dynamic>?) != null
          ? Map<String, dynamic>.from(adaptiveMap['data'] as Map)
          : <String, dynamic>{},
      inputValues: values,
      associatedInputs: adaptiveMap['associatedInputs'] as String?,
    );

    if (!validateInputs(container)) return;

    final invoke = SubmitActionInvoke.fromActionMap(adaptiveMap, data);

    final foo = InheritedAdaptiveCardHandlers.of(context);
    if (foo != null) {
      foo.onSubmit(invoke);
    } else if (kDebugMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No custom handler found for onSubmit: '
            'id: ${invoke.actionId}\n ${invoke.data}',
          ),
        ),
      );
    }
  }
}

/// Default actions for onTaps for Action.Execute
/// Expects there to be supplementary data in 'data' property
class DefaultExecuteAction extends GenericExecuteAction {
  /// Validates inputs, merges `data`, and forwards to
  /// [InheritedAdaptiveCardHandlers.onExecute].
  const DefaultExecuteAction();

  @override
  void tap({
    required BuildContext context,
    required RawAdaptiveCardState rawAdaptiveCardState,
    required Map<String, dynamic> adaptiveMap,
  }) {
    final container = ProviderScope.containerOf(context);
    final values = container
        .read(adaptiveCardDocumentProvider.notifier)
        .collectInputValues();

    final data = mergeActionData(
      actionData: (adaptiveMap['data'] as Map<String, dynamic>?) != null
          ? Map<String, dynamic>.from(adaptiveMap['data'] as Map)
          : <String, dynamic>{},
      inputValues: values,
      associatedInputs: adaptiveMap['associatedInputs'] as String?,
    );
    if (!validateInputs(container)) return;

    final invoke = ExecuteActionInvoke.fromActionMap(adaptiveMap, data);

    final foo = InheritedAdaptiveCardHandlers.of(context);
    if (foo != null) {
      foo.onExecute(invoke);
    } else if (kDebugMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No custom handler found for onExecute: '
            'verb: ${invoke.verb} id: ${invoke.actionId}\n ${invoke.data}',
          ),
        ),
      );
    }
  }
}

/// Default handler for `Action.Http`.
///
/// **Deprecated/legacy:** `Action.Http` was the original Adaptive Cards HTTP
/// action model (schema v1.0), superseded by `Action.Execute` (Universal Action
/// Model, schema v1.4). It is still used by Outlook Actionable Messages.
///
/// Validates inputs, resolves `{{inputId.value}}` substitution, gates the URL
/// against the active URI policy, then forwards an [HttpActionInvoke] to
/// [InheritedAdaptiveCardHandlers.onHttp]. The core library never performs the
/// request itself; wire a host handler (for example
/// `flutter_adaptive_cards_host_fs`) to do the GET/POST.
class DefaultHttpAction extends GenericHttpAction {
  /// Creates the default `Action.Http` handler.
  const DefaultHttpAction();

  @override
  void tap({
    required BuildContext context,
    required RawAdaptiveCardState rawAdaptiveCardState,
    required Map<String, dynamic> adaptiveMap,
  }) {
    final container = ProviderScope.containerOf(context);

    if (!validateInputs(container)) return;

    final values = container
        .read(adaptiveCardDocumentProvider.notifier)
        .collectInputValues();

    final invoke = HttpActionInvoke.fromActionMap(adaptiveMap, values);

    // Untrusted card JSON controls this URL. Validate against the active policy
    // before forwarding, mirroring DefaultOpenUrlAction.
    final validation = InheritedAdaptiveCardSecurityPolicy.uriPolicyOf(
      context,
    ).validate(invoke.url);
    if (validation case AdaptiveUriDenied(:final reason)) {
      if (kDebugMode) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Action.Http URL blocked: $reason')),
        );
      }
      return;
    }

    // Surface card-controlled credential headers so authors notice untrusted
    // injection. The header still forwards; the host decides what to do.
    for (final header in invoke.headers) {
      final lname = header.name.toLowerCase();
      if (lname == 'authorization' || lname == 'cookie') {
        assert(() {
          developer.log(
            'Action.Http carries a sensitive header from card JSON: '
            '${header.name}',
          );
          return true;
        }());
      }
    }

    final handlers = InheritedAdaptiveCardHandlers.of(context);
    if (handlers?.onHttp != null) {
      handlers!.onHttp!(invoke);
    } else if (kDebugMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No custom handler found for onHttp: '
            '${invoke.method} ${invoke.url}',
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
  /// Forwards to [InheritedAdaptiveCardHandlers.onOpenUrl] or launches the URL.
  const DefaultOpenUrlAction();

  @override
  void tap({
    required BuildContext context,
    required RawAdaptiveCardState rawAdaptiveCardState,
    required Map<String, dynamic> adaptiveMap,
    String? altUrl,
  }) {
    final invoke = OpenUrlActionInvoke.fromActionMap(
      adaptiveMap,
      altUrl: altUrl,
    );
    if (invoke.url.isEmpty) return;

    // Untrusted card JSON controls this URL. Validate against the active
    // policy before either forwarding to the host or launching it, so a
    // malicious scheme/host cannot reach a host handler or url_launcher.
    final validation = InheritedAdaptiveCardSecurityPolicy.uriPolicyOf(
      context,
    ).validate(invoke.url);
    if (validation case AdaptiveUriDenied(:final reason)) {
      if (kDebugMode) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('URL blocked: $reason')),
        );
      }
      return;
    }

    final foo = InheritedAdaptiveCardHandlers.of(context);
    if (foo != null) {
      foo.onOpenUrl(invoke);
    } else {
      unawaited(launchUrl(Uri.parse(invoke.url)));
      if (kDebugMode) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No custom handler found for onOpenUrl: \n ${invoke.url}',
            ),
          ),
        );
      }
    }
  }
}

/// Default actions for onTaps for Action.OpenUrlDialog
///
/// idential to DefaultOpenUrlAction for now
class DefaultOpenUrlDialogAction extends GenericActionOpenUrlDialog {
  /// Forwards to [InheritedAdaptiveCardHandlers.onOpenUrlDialog] or shows the
  /// built-in dialog.
  const DefaultOpenUrlDialogAction();

  @override
  void tap({
    required BuildContext context,
    required RawAdaptiveCardState rawAdaptiveCardState,
    required Map<String, dynamic> adaptiveMap,
    String? altUrl,
  }) {
    final invoke = OpenUrlDialogActionInvoke.fromActionMap(
      adaptiveMap,
      altUrl: altUrl,
    );
    if (invoke.url.isEmpty) return;

    final foo = InheritedAdaptiveCardHandlers.of(context);
    if (foo != null) {
      foo.onOpenUrlDialog(invoke);
    } else {
      unawaited(
        showOpenUrlDialog(
          context: context,
          url: invoke.url,
          hostConfigs: rawAdaptiveCardState.widget.hostConfigs,
        ),
      );
    }
  }
}

/// Default actions for Action.ResetInputs
/// Resets the form
class DefaultResetInputsAction extends GenericActionResetInputs {
  /// Resets targeted inputs via [executeResetInputsAction].
  const DefaultResetInputsAction();

  @override
  void tap({
    required BuildContext context,
    required RawAdaptiveCardState rawAdaptiveCardState,
    required Map<String, dynamic> adaptiveMap,
  }) {
    executeResetInputsAction(context, adaptiveMap);
  }
}

/// Default handler for `Action.Popover` — shows the nested `card` payload
/// in a modal dialog, inheriting HostConfig from the parent card.
class DefaultPopoverAction extends GenericPopoverAction {
  /// Creates a default popover action handler.
  const DefaultPopoverAction();

  @override
  void tap({
    required BuildContext context,
    required RawAdaptiveCardState rawAdaptiveCardState,
    required Map<String, dynamic> adaptiveMap,
  }) {
    final card = adaptiveMap['card'] as Map<String, dynamic>?;
    if (card == null) return;

    unawaited(
      showDialog<void>(
        context: context,
        builder: (context) => Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
            child: SingleChildScrollView(
              child: AdaptivePopoverContainer(
                child: RawAdaptiveCard.fromMap(
                  map: card,
                  hostConfigs: rawAdaptiveCardState.widget.hostConfigs,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Default actions for Action.ToggleVisibility
///
class DefaultToggleVisibilityAction extends GenericActionToggleVisibility {
  /// Toggles visibility for each `targetElements` entry via the document
  /// notifier.
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
