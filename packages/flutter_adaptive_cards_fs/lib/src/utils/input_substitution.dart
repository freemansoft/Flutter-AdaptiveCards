/// Input value substitution for `Action.Http` (non-standard, Outlook Actionable
/// Messages origin).
///
/// `Action.Http` `url`, `body`, and header `value` strings may embed
/// `{{inputId.value}}` placeholders that are replaced with the current value of
/// the input whose `id` matches `inputId`. See
/// <https://learn.microsoft.com/en-us/outlook/actionable-messages/adaptive-card>.
///
/// This is the literal Outlook `{{id.value}}` form only; it is intentionally
/// unrelated to the `flutter_adaptive_template_fs` templating engine (`${...}`).
library;

/// Matches `{{ inputId.value }}` tokens, capturing the input id. Surrounding
/// whitespace inside the braces is tolerated.
final RegExp _tokenPattern = RegExp(r'\{\{\s*([\w.-]+)\.value\s*\}\}');

/// Replaces every `{{inputId.value}}` token in [template] with the matching
/// entry from [inputValues].
///
/// Unknown ids (no entry in [inputValues], or a `null` value) resolve to an
/// empty string, matching the Outlook substitution behavior. Text containing no
/// tokens is returned unchanged.
String substituteInputValues(
  String template,
  Map<String, dynamic> inputValues,
) {
  if (!template.contains('{{')) return template;
  return template.replaceAllMapped(_tokenPattern, (match) {
    final id = match.group(1)!;
    final value = inputValues[id];
    return value?.toString() ?? '';
  });
}
