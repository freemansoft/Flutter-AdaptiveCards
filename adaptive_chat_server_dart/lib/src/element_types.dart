/// The element-type vocabulary the client can render, and the check for a
/// reply that strays outside it.
///
/// An invented or misspelled `type` is still valid JSON, so it passes card
/// detection and then renders as an empty blank rather than an error. That
/// makes it the one failure users can see and no probe can score, because
/// every probe judges a reply by whether it parses as a card. Reading the
/// vocabulary from the shipped schema — rather than a list kept here — means
/// the check tracks what the client actually renders.
///
/// Kept out of `card_detect.dart` on purpose: that library is pure and
/// parses strings, while this one reads a file.
library;

import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';

final _log = Logger('adaptive_chat_server_dart.element_types');

/// Reads the renderable element vocabulary from the card schema at [path].
///
/// Returns the `$defs/ChildElement` enum, which covers every legal position
/// including nesting-only types such as `Column` and `TableRow` — a walker
/// over a whole card body needs all of them, not just the top-level set.
///
/// Returns an empty set when the schema is missing, malformed, or shaped
/// unexpectedly, after logging why. Callers treat an empty set as "check
/// disabled", so a broken tuning asset degrades the check instead of failing
/// every request — the same trade `loadSeedCardMessages` makes.
Set<String> loadKnownElementTypes(String path) {
  final String raw;
  try {
    raw = File(path).readAsStringSync();
  } on IOException catch (e) {
    _log.warning(
      'Card schema unreadable ($e) at $path — unknown-element-type '
      'checking is disabled for this process.',
    );
    return const {};
  }

  final Object? decoded;
  try {
    decoded = jsonDecode(raw);
  } on FormatException catch (e) {
    _log.warning(
      'Card schema is not valid JSON ($e) at $path — unknown-element-type '
      'checking is disabled for this process.',
    );
    return const {};
  }

  if (decoded is! Map<String, dynamic>) return _disabled(path);
  final defs = decoded[r'$defs'];
  if (defs is! Map<String, dynamic>) return _disabled(path);
  final child = defs['ChildElement'];
  if (child is! Map<String, dynamic>) return _disabled(path);
  final properties = child['properties'];
  if (properties is! Map<String, dynamic>) return _disabled(path);
  final type = properties['type'];
  if (type is! Map<String, dynamic>) return _disabled(path);
  final values = type['enum'];
  if (values is! List) return _disabled(path);
  return values.whereType<String>().toSet();
}

Set<String> _disabled(String path) {
  _log.warning(
    'Card schema at $path has no usable '
    r'$defs/ChildElement/properties/type/enum — unknown-element-type '
    'checking is disabled for this process.',
  );
  return const {};
}

/// `type` values that are legal in a card but absent from `$defs/ChildElement`
/// on purpose, because that enum is an *element* vocabulary and these are not
/// elements.
///
/// `ChildElement` only names things that can occupy a body/child position.
/// `TextRun` occupies a `RichTextBlock.inlines` slot, `AdaptiveCard` occupies
/// `Action.ShowCard.card`, and every `Action.*` occupies an `actions` array —
/// none of those is a body element, so the enum rightly excludes them. But a
/// walker over a whole reply cannot tell "excluded because illegal" from
/// "excluded because it belongs somewhere else": flagging these produces
/// exactly the false positive this check exists to avoid, on cards the client
/// renders perfectly.
bool _isTolerableNonElement(String type) =>
    type == 'AdaptiveCard' || type == 'TextRun' || type.startsWith('Action.');

/// Every `type` value in [body], at any depth, that is absent from [known]
/// and not a [_isTolerableNonElement] value.
///
/// Walks nested arrays and objects, so a bad type inside a `Column`, a
/// `TableCell`, or a `Carousel` page is caught — that is where deep nesting
/// puts most real occurrences.
///
/// Returns an empty set when [known] is empty, so a failed vocabulary load
/// disables the check rather than flagging every element of every reply.
Set<String> unknownElementTypes(
  List<Map<String, dynamic>> body,
  Set<String> known,
) {
  if (known.isEmpty) return const {};
  final unknown = <String>{};
  void walk(Object? node) {
    if (node is Map) {
      final type = node['type'];
      // Only a `type` key names an element; an ordinary string value that
      // happens to look like a type name must not be flagged.
      if (type is String &&
          type.isNotEmpty &&
          !known.contains(type) &&
          !_isTolerableNonElement(type)) {
        unknown.add(type);
      }
      node.values.forEach(walk);
    } else if (node is List) {
      node.forEach(walk);
    }
  }

  body.forEach(walk);
  return unknown;
}
