/// Returns whether [value] satisfies Adaptive Card `Input.Text` validation
/// rules for [isRequired] and optional [regexPattern].
bool textInputValueIsValid({
  required String? value,
  required bool isRequired,
  required String? regexPattern,
}) {
  final text = value ?? '';

  if (isRequired && text.isEmpty) {
    return false;
  }

  if (regexPattern != null &&
      regexPattern.isNotEmpty &&
      text.isNotEmpty &&
      !_matchesRegex(text, regexPattern)) {
    return false;
  }

  return true;
}

bool _matchesRegex(String text, String pattern) {
  try {
    return RegExp(pattern).hasMatch(text);
  } on FormatException {
    return true;
  }
}
