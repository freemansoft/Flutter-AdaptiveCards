/// Decide whether a model reply is *only* an Adaptive Card, and extract its
/// body.
///
/// The entire reply (after stripping an optional code fence) must be the
/// card, or it is treated as text. Three fragment shapes are accepted,
/// because local models emit all three:
///   1. a full card object `{"type": "AdaptiveCard", "body": [...]}` -> its
///      body
///   2. a bare array `[{...}, {...}]` -> as-is
///   3. a single element `{"type": "Input.ChoiceSet", ...}` -> `[element]`
/// A dict with no `type` string, a scalar, or an empty/mixed array is
/// treated as text.
library;

import 'dart:convert';

// Matches a whole reply wrapped in a balanced ```json ... ``` (or bare ```)
// fence.
final _fence = RegExp(
  r'^\s*```(?:json)?\s*(.*?)\s*```\s*$',
  dotAll: true,
  caseSensitive: false,
);

// Unbalanced fence markers a model leaves when it opens a fence but never
// closes it (or vice versa).
final _openFence = RegExp(r'^```[^\n{\[]*\r?\n?');
final _closeFence = RegExp(r'\r?\n?```[^\n]*$');

// Leading/trailing decoration a local model wraps around the JSON:
// whitespace and runs of section/Markdown delimiters.
final _decoration = RegExp(r'^[\s=\-#*_~]+|[\s=\-#*_~]+$');

String _stripFence(String raw) {
  var text = raw.trim();
  final match = _fence.firstMatch(text);
  if (match != null) {
    return match.group(1)!;
  }
  text = text.replaceFirst(_openFence, '');
  text = text.replaceFirst(_closeFence, '');
  return text.trim();
}

String _stripDecoration(String text) => text.replaceAll(_decoration, '');

/// Returns Adaptive Card body items if [raw] is *only* a card, else `null`.
List<Map<String, dynamic>>? tryParseCardBody(String raw) {
  final text = _stripDecoration(_stripFence(raw));
  dynamic parsed;
  try {
    parsed = jsonDecode(text);
  } on FormatException {
    return null;
  }
  if (parsed is List) {
    if (parsed.isNotEmpty && parsed.every((item) => item is Map)) {
      return parsed.cast<Map<String, dynamic>>();
    }
    return null;
  }
  if (parsed is Map) {
    final map = Map<String, dynamic>.from(parsed);
    if (map['type'] == 'AdaptiveCard') {
      final body = map['body'];
      return body is List &&
              body.isNotEmpty &&
              body.every((item) => item is Map)
          ? body.cast<Map<String, dynamic>>()
          : null;
    }
    final elementType = map['type'];
    if (elementType is String && elementType.isNotEmpty) {
      return [map];
    }
  }
  return null;
}

/// Explains why a reply that *looked like* a card was not rendered as one.
///
/// Diagnostic/logging aid only. Returns `null` when [raw] is a valid card
/// or is plainly prose (does not begin with `{`/`[` after decoration
/// stripping). Returns a short reason when the reply *began* like JSON but
/// could not be used.
String? cardParseFailureReason(String raw) {
  final text = _stripDecoration(_stripFence(raw));
  if (text.isEmpty || !(text.startsWith('{') || text.startsWith('['))) {
    return null;
  }
  try {
    jsonDecode(text);
  } on FormatException catch (e) {
    return 'invalid JSON: $e';
  }
  if (tryParseCardBody(raw) != null) return null;
  return 'valid JSON but not a renderable card '
      "(empty body, missing 'type', or empty/mixed array)";
}
