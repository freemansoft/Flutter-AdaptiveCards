/// Loads the bundled "conversation no longer exists" notice card body.
library;

import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';

final _log = Logger('adaptive_chat_server_dart');

const _fallbackNoticeText =
    'This conversation no longer exists on the server (it likely '
    'restarted). Continuing as a new session.';

/// Built-in notice body, used when the bundled JSON asset is missing or
/// invalid, and as `buildHandler`'s default for callers (tests, before
/// `bin/server.dart` wires up the real asset) that don't supply their own.
const List<Map<String, dynamic>> fallbackExpiredConversationBodyItems = [
  {'type': 'TextBlock', 'text': _fallbackNoticeText, 'wrap': true},
];

/// Reads [path] as a JSON array of Adaptive Card body items for the
/// "conversation no longer exists" notice, prepended to the envelope when a
/// client's `conversationId` is unknown to the store (see `app.dart`).
///
/// Loaded once, at server startup — like `card_schema.json` — rather than
/// per-request, since the wording changes rarely. Falls back to a small
/// built-in notice (logging why) when [path] is missing, unreadable, not
/// valid JSON, or not a JSON array, so a bad asset never breaks the
/// endpoint it's used from.
List<Map<String, dynamic>> loadExpiredConversationBodyItems(String path) {
  Object? decoded;
  try {
    decoded = jsonDecode(File(path).readAsStringSync());
  } on FormatException catch (e) {
    _log.warning(
      'Expired-conversation notice unusable (invalid JSON: $e) at $path — '
      'using the built-in fallback.',
    );
    return fallbackExpiredConversationBodyItems;
  } on IOException catch (e) {
    _log.warning(
      'Expired-conversation notice unusable ($e) at $path — using the '
      'built-in fallback.',
    );
    return fallbackExpiredConversationBodyItems;
  }
  if (decoded is! List) {
    _log.warning(
      'Expired-conversation notice at $path is not a JSON array — using '
      'the built-in fallback.',
    );
    return fallbackExpiredConversationBodyItems;
  }
  return decoded.cast<Map<String, dynamic>>();
}
