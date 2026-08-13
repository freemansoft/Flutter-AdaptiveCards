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

/// Restores the `[ ]` around top-level objects a model emitted without them.
///
/// Asked for two elements (e.g. a TextBlock explaining a CodeBlock), a small
/// model often writes them comma-separated at the top level and drops the
/// enclosing brackets. That is the bare-array shape missing its brackets and
/// nothing else, so restoring them recovers the card instead of showing the
/// user raw JSON.
///
/// Deliberately narrow: it only fires on text the caller has already failed
/// to parse, and only keeps the result when bracketing makes it parse. A
/// reply with prose after the card does not end in `}` and would not parse
/// bracketed either, so it stays a text reply — see the "does not rescue
/// trailing prose" test.
String _repairMissingArrayBrackets(String text) {
  if (!text.startsWith('{') || !text.endsWith('}')) return text;
  final bracketed = '[$text]';
  try {
    jsonDecode(bracketed);
    return bracketed;
  } on FormatException {
    return text;
  }
}

/// Prepares a reply for `jsonDecode`, repairing it only if it needs repair.
///
/// Fence and decoration stripping exist for models that wrap their answer in
/// Markdown. Running them over a reply that **already parses** can only
/// corrupt it: the unbalanced-closing-fence pattern matches any ``` run
/// through end-of-line, so a single-line card whose own text opens a
/// ` ```dart ` snippet had everything from that fence onward deleted and
/// arrived as truncated, unparseable JSON. Parsing first keeps a
/// well-formed reply untouched and leaves the heuristics for replies that
/// actually are wrapped.
String _normalizeForParsing(String raw) {
  final trimmed = raw.trim();
  try {
    jsonDecode(trimmed);
    return trimmed;
  } on FormatException {
    final stripped = _stripDecoration(_stripFence(raw));
    try {
      jsonDecode(stripped);
      return stripped;
    } on FormatException {
      // Only now, with the reply still unparseable, is bracket repair safe:
      // a `{"type":"AdaptiveCard",…}` that already parses must keep its
      // full-card meaning rather than becoming a one-item array.
      return _repairMissingArrayBrackets(stripped);
    }
  }
}

/// Returns Adaptive Card body items if [raw] is *only* a card, else `null`.
List<Map<String, dynamic>>? tryParseCardBody(String raw) {
  final text = _normalizeForParsing(raw);
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
  final text = _normalizeForParsing(raw);
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
