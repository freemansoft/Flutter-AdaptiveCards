import 'dart:convert';
import 'dart:io';

import 'package:adaptive_chat_server_dart/src/expired_conversation.dart';
import 'package:test/test.dart';

// loadExpiredConversationBodyItems reads an operator-editable JSON asset
// (the "conversation no longer exists" notice shown when a client's
// conversationId is unknown after a server restart) at startup. This suite
// guards the fallback contract: a missing, unreadable, malformed, or
// wrong-shaped asset must degrade to the built-in notice rather than crash
// server startup — an operator customizing the wording who breaks the file
// should get a bland default notice, not a server that won't boot.
void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('expired_conversation_test');
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  // The happy path is the baseline the three fallback tests below are
  // contrasting against — confirms a well-formed custom notice is used
  // verbatim, not silently replaced by the built-in one.
  test('loads a bundled JSON array of card body items', () {
    final path = '${tempDir.path}/notice.json';
    File(path).writeAsStringSync(
      jsonEncode([
        {'type': 'TextBlock', 'text': 'custom notice', 'wrap': true},
      ]),
    );

    final items = loadExpiredConversationBodyItems(path);

    expect(items, [
      {'type': 'TextBlock', 'text': 'custom notice', 'wrap': true},
    ]);
  });

  // A missing file is the ordinary case before an operator has customized
  // the notice at all — this must not be treated as an error worth
  // preventing startup over.
  test('falls back to a built-in notice when the file is missing', () {
    final items = loadExpiredConversationBodyItems(
      '${tempDir.path}/missing.json',
    );

    expect(items, isNotEmpty);
    expect(items.single['type'], 'TextBlock');
  });

  // Distinct code path from the missing-file case (FormatException vs.
  // IOException) — a hand-edited notice file is exactly where a syntax
  // typo is likely, so this path gets exercised on its own.
  test('falls back to a built-in notice when the file is invalid JSON', () {
    final path = '${tempDir.path}/bad.json';
    File(path).writeAsStringSync('not json');

    final items = loadExpiredConversationBodyItems(path);

    expect(items, isNotEmpty);
    expect(items.single['type'], 'TextBlock');
  });

  // Valid JSON but the wrong shape (a bare object instead of an array) is a
  // third distinct failure mode, checked after jsonDecode succeeds — the
  // one this file's own type-check (`decoded is! List`) exists to catch,
  // separate from the two exception-based fallbacks above.
  test('falls back to a built-in notice when the file is not a JSON array', () {
    final path = '${tempDir.path}/object.json';
    File(path).writeAsStringSync(jsonEncode({'type': 'TextBlock'}));

    final items = loadExpiredConversationBodyItems(path);

    expect(items, isNotEmpty);
    expect(items.single['type'], 'TextBlock');
  });
}
