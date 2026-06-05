import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/riverpod/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Executes `Action.ResetInputs` from `actionMap`, honoring `targetInputIds`.
///
/// Omitted or null `targetInputIds` resets all inputs; an empty array is a no-op.
void executeResetInputsAction(
  BuildContext context,
  Map<String, dynamic> actionMap,
) {
  final container = ProviderScope.containerOf(context);
  final notifier = container.read(adaptiveCardDocumentProvider.notifier);

  if (!actionMap.containsKey('targetInputIds')) {
    notifier.resetAllInputs();
    return;
  }

  final raw = actionMap['targetInputIds'];
  if (raw == null) {
    notifier.resetAllInputs();
    return;
  }

  if (raw is! List || raw.isEmpty) {
    return;
  }

  final ids = <String>[
    for (final entry in raw)
      if (entry is String) entry,
  ];

  if (ids.isEmpty) {
    return;
  }

  notifier.resetInputs(ids);
}
