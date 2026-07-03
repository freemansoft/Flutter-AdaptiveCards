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
class SubmitActionInvoke {
  /// Creates a submit callback payload with merged [data] and optional
  /// [actionId].
  const SubmitActionInvoke({
    required this.data,
    this.actionId,
  });

  /// Builds from action JSON and collected input [data].
  factory SubmitActionInvoke.fromActionMap(
    Map<String, dynamic> actionMap,
    Map<String, dynamic> data,
  ) {
    return SubmitActionInvoke(
      data: data,
      actionId: actionIdFromMap(actionMap),
    );
  }

  /// Merged `Action.Submit.data` and collected input values (inputs win on
  /// key collision).
  final Map<String, dynamic> data;

  /// Author-defined action `id` from card JSON, when present.
  final String? actionId;
}

/// Payload delivered to the host `onRefresh` callback.
///
/// Wraps the nested `refresh.action` map plus merged input values. When no
/// `onRefresh` handler is installed, the library falls back to `onExecute`.
class RefreshActionInvoke {
  /// Creates a refresh callback payload with merged [data], [verb], and
  /// [actionId].
  const RefreshActionInvoke({
    required this.data,
    this.verb,
    this.actionId,
  });

  /// Builds from `refresh.action` JSON and collected input [data].
  factory RefreshActionInvoke.fromActionMap(
    Map<String, dynamic> actionMap,
    Map<String, dynamic> data,
  ) {
    return RefreshActionInvoke(
      data: data,
      verb: actionMap['verb']?.toString(),
      actionId: actionIdFromMap(actionMap),
    );
  }

  /// Merged action `data` and collected input values (inputs win on key
  /// collision).
  final Map<String, dynamic> data;

  /// Verb from the nested `Action.Execute` map.
  final String? verb;

  /// Author-defined action `id` from the nested action JSON, when present.
  final String? actionId;
}

/// Payload delivered to the host `onExecute` callback.
///
/// Contains merged action `data` and input values in `data`, plus optional
/// `verb` and author-defined `actionId` from the action JSON.
class ExecuteActionInvoke {
  /// Creates an execute callback payload with merged [data], [verb], and
  /// [actionId].
  const ExecuteActionInvoke({
    required this.data,
    this.verb,
    this.actionId,
  });

  /// Builds from action JSON and collected input [data].
  factory ExecuteActionInvoke.fromActionMap(
    Map<String, dynamic> actionMap,
    Map<String, dynamic> data,
  ) {
    return ExecuteActionInvoke(
      data: data,
      verb: actionMap['verb']?.toString(),
      actionId: actionIdFromMap(actionMap),
    );
  }

  /// Merged `Action.Execute.data` and collected input values (inputs win on
  /// key collision).
  final Map<String, dynamic> data;

  /// Card author-defined verb from action JSON (`verb` property).
  final String? verb;

  /// Author-defined action `id` from card JSON, when present.
  final String? actionId;
}

/// Payload delivered to the host `onOpenUrl` callback.
class OpenUrlActionInvoke {
  /// Creates an open-URL callback payload for [url] with optional [actionId].
  const OpenUrlActionInvoke({
    required this.url,
    this.actionId,
  });

  /// Builds from action JSON, using [altUrl] when supplied by selectAction.
  factory OpenUrlActionInvoke.fromActionMap(
    Map<String, dynamic> actionMap, {
    String? altUrl,
  }) {
    final urlFromMap = actionMap['url'] as String?;
    return OpenUrlActionInvoke(
      url: altUrl ?? urlFromMap ?? '',
      actionId: actionIdFromMap(actionMap),
    );
  }

  /// URL from action JSON (or `altUrl` when supplied by selectAction routing).
  final String url;

  /// Author-defined action `id` from card JSON, when present.
  final String? actionId;
}

/// Payload delivered to the host `onOpenUrlDialog` callback.
class OpenUrlDialogActionInvoke {
  /// Creates an open-URL-in-dialog callback payload for [url].
  const OpenUrlDialogActionInvoke({
    required this.url,
    this.actionId,
  });

  /// Builds from action JSON, using [altUrl] when supplied by selectAction.
  factory OpenUrlDialogActionInvoke.fromActionMap(
    Map<String, dynamic> actionMap, {
    String? altUrl,
  }) {
    final urlFromMap = actionMap['url'] as String?;
    return OpenUrlDialogActionInvoke(
      url: altUrl ?? urlFromMap ?? '',
      actionId: actionIdFromMap(actionMap),
    );
  }

  /// URL from action JSON (or `altUrl` when supplied by selectAction routing).
  final String url;

  /// Author-defined action `id` from card JSON, when present.
  final String? actionId;
}

/// A single HTTP header carried by an [HttpActionInvoke].
///
/// Headers are kept as an ordered list (rather than a map) so author order is
/// preserved and duplicate header names are allowed.
class HttpActionHeader {
  /// Creates a header with [name] and resolved [value].
  const HttpActionHeader({required this.name, required this.value});

  /// Header field name, for example `Content-Type`.
  final String name;

  /// Header value, after `{{inputId.value}}` substitution.
  final String value;
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
class HttpActionInvoke {
  /// Creates an HTTP action payload with already-resolved request fields.
  const HttpActionInvoke({
    required this.method,
    required this.url,
    required this.headers,
    required this.inputValues,
    this.body,
    this.actionId,
  });

  /// Builds from `Action.Http` JSON and collected [inputValues].
  ///
  /// `method` is upper-cased; `url`, `body`, and each header `value` have
  /// `{{inputId.value}}` tokens substituted from [inputValues].
  factory HttpActionInvoke.fromActionMap(
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

  /// HTTP method, upper-cased (`GET` or `POST`).
  final String method;

  /// Target URL, after `{{inputId.value}}` substitution.
  final String url;

  /// Request body, after substitution; `null` when the action has no `body`.
  final String? body;

  /// Request headers in author order, with values substituted.
  final List<HttpActionHeader> headers;

  /// Raw collected input values, before substitution.
  final Map<String, dynamic> inputValues;

  /// Author-defined action `id` from card JSON, when present.
  final String? actionId;
}

/// Payload delivered to the host `onSignin` callback for a card
/// `authentication` sign-in button.
///
/// [value] is the sign-in URL the host opens; [connectionName] is the OAuth
/// connection the host uses to complete sign-in. When no `onSignin` handler is
/// installed, the library falls back to `onOpenUrl` for an http(s) [value].
class SigninActionInvoke {
  /// Creates a sign-in callback payload.
  const SigninActionInvoke({
    required this.value,
    this.connectionName,
    this.actionId,
  });

  /// Builds from an [AuthCardButton] and the parent
  /// [AuthenticationConfig.connectionName].
  factory SigninActionInvoke.fromButton(
    AuthCardButton button, {
    String? connectionName,
  }) {
    return SigninActionInvoke(
      value: button.value ?? '',
      connectionName: connectionName,
    );
  }

  /// Sign-in URL / action value from the button JSON.
  final String value;

  /// OAuth connection name from the parent `authentication` object.
  final String? connectionName;

  /// Author-defined action `id`, when present. Reserved for future use.
  final String? actionId;
}

/// Payload delivered to the host `onChange` callback when an input value
/// changes.
class InputChangeInvoke {
  /// Creates an input-change callback for [inputId] with the new [value].
  const InputChangeInvoke({
    required this.inputId,
    required this.value,
    required this.cardState,
    this.dataQuery,
  });

  /// Input element `id` from card JSON.
  final String inputId;

  /// New input value (ChoiceSet stores choice `value`, not title).
  final dynamic value;

  /// Parsed `choices.data` when the input defines a Data.Query.
  final DataQuery? dataQuery;

  /// Card state for host APIs such as `applyUpdates`.
  final RawAdaptiveCardState cardState;
}
