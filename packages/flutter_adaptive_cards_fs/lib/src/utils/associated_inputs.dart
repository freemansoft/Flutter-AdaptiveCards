/// Whether sibling inputs should be merged (Teams default: auto when omitted).
bool shouldMergeAssociatedInputs(String? associatedInputs) {
  return associatedInputs != 'none';
}

/// Merges [siblingValues] into [existingParameters], excluding [excludeInputId].
Map<String, dynamic> mergeSiblingInputParameters({
  required Map<String, dynamic> siblingValues,
  required String excludeInputId,
  Map<String, dynamic>? existingParameters,
}) {
  final params = Map<String, dynamic>.from(existingParameters ?? {});
  for (final entry in siblingValues.entries) {
    if (entry.key == excludeInputId) continue;
    params[entry.key] = entry.value;
  }
  return params;
}

/// Builds Submit/Execute invoke `data` honoring [associatedInputs].
Map<String, dynamic> mergeActionData({
  required Map<String, dynamic> actionData,
  required Map<String, dynamic> inputValues,
  required String? associatedInputs,
}) {
  if (!shouldMergeAssociatedInputs(associatedInputs)) {
    return Map<String, dynamic>.from(actionData);
  }
  return Map<String, dynamic>.from(actionData)..addAll(inputValues);
}
