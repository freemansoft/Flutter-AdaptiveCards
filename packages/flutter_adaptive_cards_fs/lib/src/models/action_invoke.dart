import 'package:flutter_adaptive_cards_fs/src/flutter_raw_adaptive_card.dart';
import 'package:flutter_adaptive_cards_fs/src/models/authentication_config.dart';
import 'package:flutter_adaptive_cards_fs/src/models/data_query.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/input_substitution.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';

/// Reads author-defined action `id` from card JSON, or null when absent or
/// auto-injected at card load.
String? actionIdFromMap(Map<String, dynamic> actionMap) {
  final idRaw = actionMap['id'];
  if (idRaw == null) return null;
  final id = idRaw.toString();
  final type = actionMap['type']?.toString();
  if (!UUIDGenerator().isNaturalId(id, type)) {
    return null;
  }
  return id;
}

/// Payload delivered to the host `onSubmit` callback.
///
/// Contains merged action `data` and input values in `data`, plus optional
/// author-defined `actionId` from the action JSON.
class const SubmitActionInvoke({
  /// Merged `Action.Submit.data` and collected input values (inputs win on
  /// key collision).
  required final Map<String, dynamic> data,

  /// Author-defined action `id` from card JSON, when present.
  final String? actionId,
}) {
  /// Creates a submit callback payload with merged [data] and optional
  /// [actionId].
  this;

  /// Builds from action JSON and collected input [data].
  factory fromActionMap(
    Map<String, dynamic> actionMap,
    Map<String, dynamic> data,
  ) {
    return SubmitActionInvoke(
      data: data,
      actionId: actionIdFromMap(actionMap),
    );
  }
}

/// Payload delivered to the host `onRefresh` callback.
///
/// Wraps the nested `refresh.action` map plus merged input values. When no
/// `onRefresh` handler is installed, the library falls back to `onExecute`.
class const RefreshActionInvoke({
  /// Merged action `data` and collected input values (inputs win on key
  /// collision).
  required final Map<String, dynamic> data,

  /// Verb from the nested `Action.Execute` map.
  final String? verb,

  /// Author-defined action `id` from the nested action JSON, when present.
  final String? actionId,
}) {
  /// Creates a refresh callback payload with merged [data], [verb], and
  /// [actionId].
  this;

  /// Builds from `refresh.action` JSON and collected input [data].
  factory fromActionMap(
    Map<String, dynamic> actionMap,
    Map<String, dynamic> data,
  ) {
    return RefreshActionInvoke(
      data: data,
      verb: actionMap['verb']?.toString(),
      actionId: actionIdFromMap(actionMap),
    );
  }
}

/// Payload delivered to the host `onExecute` callback.
///
/// Contains merged action `data` and input values in `data`, plus optional
/// `verb` and author-defined `actionId` from the action JSON.
class const ExecuteActionInvoke({
  /// Merged `Action.Execute.data` and collected input values (inputs win on
  /// key collision).
  required final Map<String, dynamic> data,

  /// Card author-defined verb from action JSON (`verb` property).
  final String? verb,

  /// Author-defined action `id` from card JSON, when present.
  final String? actionId,
}) {
  /// Creates an execute callback payload with merged [data], [verb], and
  /// [actionId].
  this;

  /// Builds from action JSON and collected input [data].
  factory fromActionMap(
    Map<String, dynamic> actionMap,
    Map<String, dynamic> data,
  ) {
    return ExecuteActionInvoke(
      data: data,
      verb: actionMap['verb']?.toString(),
      actionId: actionIdFromMap(actionMap),
    );
  }
}

/// Payload delivered to the host `onOpenUrl` callback.
class const OpenUrlActionInvoke({
  /// URL from action JSON (or `altUrl` when supplied by selectAction routing).
  required final String url,

  /// Author-defined action `id` from card JSON, when present.
  final String? actionId,
}) {
  /// Creates an open-URL callback payload for [url] with optional [actionId].
  this;

  /// Builds from action JSON, using [altUrl] when supplied by selectAction.
  factory fromActionMap(
    Map<String, dynamic> actionMap, {
    String? altUrl,
  }) {
    final urlFromMap = actionMap['url'] as String?;
    return OpenUrlActionInvoke(
      url: altUrl ?? urlFromMap ?? '',
      actionId: actionIdFromMap(actionMap),
    );
  }
}

/// Payload delivered to the host `onOpenUrlDialog` callback.
class const OpenUrlDialogActionInvoke({
  /// URL from action JSON (or `altUrl` when supplied by selectAction routing).
  required final String url,

  /// Author-defined action `id` from card JSON, when present.
  final String? actionId,
}) {
  /// Creates an open-URL-in-dialog callback payload for [url].
  this;

  /// Builds from action JSON, using [altUrl] when supplied by selectAction.
  factory fromActionMap(
    Map<String, dynamic> actionMap, {
    String? altUrl,
  }) {
    final urlFromMap = actionMap['url'] as String?;
    return OpenUrlDialogActionInvoke(
      url: altUrl ?? urlFromMap ?? '',
      actionId: actionIdFromMap(actionMap),
    );
  }
}

/// A single HTTP header carried by an [HttpActionInvoke].
///
/// Headers are kept as an ordered list (rather than a map) so author order is
/// preserved and duplicate header names are allowed.
class const HttpActionHeader({
  /// Header field name, for example `Content-Type`.
  required final String name,

  /// Header value, after `{{inputId.value}}` substitution.
  required final String value,
}) {
  /// Creates a header with [name] and resolved [value].
  this;
}

/// Payload delivered to the host `onHttp` callback for `Action.Http`.
///
/// **Deprecated/legacy:** `Action.Http` was the original Adaptive Cards HTTP
/// action model (schema v1.0), superseded by `Action.Execute` (Universal Action
/// Model, schema v1.4). It is still used by Outlook Actionable Messages
/// (<https://learn.microsoft.com/en-us/outlook/actionable-messages/adaptive-card>).
/// The library resolves
/// `{{inputId.value}}` substitution in [url], [body], and header values before
/// delivering this payload, so hosts receive request-ready values and never
/// re-implement the substitution mini-language. The raw [inputValues] map is
/// included so hosts can re-derive values if needed.
class const HttpActionInvoke({
  /// HTTP method, upper-cased (`GET` or `POST`).
  required final String method,

  /// Target URL, after `{{inputId.value}}` substitution.
  required final String url,

  /// Request headers in author order, with values substituted.
  required final List<HttpActionHeader> headers,

  /// Raw collected input values, before substitution.
  required final Map<String, dynamic> inputValues,

  /// Request body, after substitution; `null` when the action has no `body`.
  final String? body,

  /// Author-defined action `id` from card JSON, when present.
  final String? actionId,
}) {
  /// Creates an HTTP action payload with already-resolved request fields.
  this;

  /// Builds from `Action.Http` JSON and collected [inputValues].
  ///
  /// `method` is upper-cased; `url`, `body`, and each header `value` have
  /// `{{inputId.value}}` tokens substituted from [inputValues].
  factory fromActionMap(
    Map<String, dynamic> actionMap,
    Map<String, dynamic> inputValues,
  ) {
    final rawUrl = actionMap['url'] as String? ?? '';
    final rawBody = actionMap['body'] as String?;
    final rawHeaders = actionMap['headers'] as List<dynamic>? ?? const [];

    final headers = <HttpActionHeader>[];
    for (final entry in rawHeaders) {
      if (entry is! Map) continue;
      final name = entry['name'] as String?;
      if (name == null) continue;
      headers.add(
        HttpActionHeader(
          name: name,
          value: substituteInputValues(
            entry['value'] as String? ?? '',
            inputValues,
          ),
        ),
      );
    }

    return HttpActionInvoke(
      method: (actionMap['method'] as String? ?? 'GET').toUpperCase(),
      url: substituteInputValues(rawUrl, inputValues),
      body: rawBody == null
          ? null
          : substituteInputValues(rawBody, inputValues),
      headers: headers,
      inputValues: inputValues,
      actionId: actionIdFromMap(actionMap),
    );
  }
}

/// Payload delivered to the host `onSignin` callback for a card
/// `authentication` sign-in button.
///
/// [value] is the sign-in URL the host opens; [connectionName] is the OAuth
/// connection the host uses to complete sign-in. When no `onSignin` handler is
/// installed, the library falls back to `onOpenUrl` for an http(s) [value].
class const SigninActionInvoke({
  /// Sign-in URL / action value from the button JSON.
  required final String value,

  /// OAuth connection name from the parent `authentication` object.
  final String? connectionName,

  /// Author-defined action `id`, when present. Reserved for future use.
  final String? actionId,
}) {
  /// Creates a sign-in callback payload.
  this;

  /// Builds from an [AuthCardButton] and the parent
  /// [AuthenticationConfig.connectionName].
  factory fromButton(
    AuthCardButton button, {
    String? connectionName,
  }) {
    return SigninActionInvoke(
      value: button.value ?? '',
      connectionName: connectionName,
    );
  }
}

/// Payload delivered to the host `onChange` callback when an input value
/// changes.
class const InputChangeInvoke({
  /// Input element `id` from card JSON.
  required final String inputId,

  /// New input value (ChoiceSet stores choice `value`, not title).
  required final dynamic value,

  /// Card state for host APIs such as `applyUpdates`.
  required final RawAdaptiveCardState cardState,

  /// Parsed `choices.data` when the input defines a Data.Query.
  final DataQuery? dataQuery,
}) {
  /// Creates an input-change callback for [inputId] with the new [value].
  this;
}
