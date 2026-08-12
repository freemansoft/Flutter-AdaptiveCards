import 'dart:convert';
import 'dart:io';

import 'package:adaptive_chat_server_dart/src/expired_conversation.dart';
import 'package:test/test.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('expired_conversation_test');
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

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

  test('falls back to a built-in notice when the file is missing', () {
    final items = loadExpiredConversationBodyItems(
      '${tempDir.path}/missing.json',
    );

    expect(items, isNotEmpty);
    expect(items.single['type'], 'TextBlock');
  });

  test('falls back to a built-in notice when the file is invalid JSON', () {
    final path = '${tempDir.path}/bad.json';
    File(path).writeAsStringSync('not json');

    final items = loadExpiredConversationBodyItems(path);

    expect(items, isNotEmpty);
    expect(items.single['type'], 'TextBlock');
  });

  test(
    'falls back to a built-in notice when the file is not a JSON array',
    () {
      final path = '${tempDir.path}/object.json';
      File(path).writeAsStringSync(jsonEncode({'type': 'TextBlock'}));

      final items = loadExpiredConversationBodyItems(path);

      expect(items, isNotEmpty);
      expect(items.single['type'], 'TextBlock');
    },
  );
}
