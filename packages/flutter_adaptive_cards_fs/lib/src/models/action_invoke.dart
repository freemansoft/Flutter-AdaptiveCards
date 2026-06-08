import 'package:flutter_adaptive_cards_fs/src/flutter_raw_adaptive_card.dart';
import 'package:flutter_adaptive_cards_fs/src/models/data_query.dart';
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
  /// Creates a submit callback payload with merged [data] and optional [actionId].
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

/// Payload delivered to the host `onExecute` callback.
///
/// Contains merged action `data` and input values in `data`, plus optional
/// `verb` and author-defined `actionId` from the action JSON.
class ExecuteActionInvoke {
  /// Creates an execute callback payload with merged [data], [verb], and [actionId].
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

/// Payload delivered to the host `onChange` callback when an input value changes.
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
