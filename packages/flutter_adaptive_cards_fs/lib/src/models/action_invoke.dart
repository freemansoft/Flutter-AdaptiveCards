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
  const SubmitActionInvoke({
    required this.data,
    this.actionId,
  });

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
  const ExecuteActionInvoke({
    required this.data,
    this.verb,
    this.actionId,
  });

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
