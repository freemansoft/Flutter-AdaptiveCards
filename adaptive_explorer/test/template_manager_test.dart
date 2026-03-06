import 'dart:convert';
import 'dart:io';

import 'package:adaptive_explorer/src/template_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late TemplateManager manager;
  late Directory tempDir;

  setUp(() {
    manager = TemplateManager();
    tempDir = Directory.systemTemp.createTempSync('template_manager_test_');
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  File createJsonFile(String name, Map<String, dynamic> content) {
    final file = File('${tempDir.path}/$name')
      ..writeAsStringSync(jsonEncode(content));
    return file;
  }

  group('TemplateManager initial state', () {
    test('templatePath is null before loading', () {
      expect(manager.templatePath, isNull);
    });

    test('dataPath is null before loading', () {
      expect(manager.dataPath, isNull);
    });

    test('getTemplateJson returns null before loading', () async {
      expect(await manager.getTemplateJson(), isNull);
    });

    test('getDataJson returns null before loading', () async {
      expect(await manager.getDataJson(), isNull);
    });

    test('getMergedJson returns null before loading', () async {
      expect(await manager.getMergedJson(), isNull);
    });
  });

  group('TemplateManager loadTemplate', () {
    test('sets templatePath', () async {
      final file = createJsonFile('template.json', <String, dynamic>{
        'type': 'AdaptiveCard',
        'body': <dynamic>[],
      });
      await manager.loadTemplate(file.path);
      expect(manager.templatePath, equals(file.path));
    });

    test('getTemplateJson returns parsed template', () async {
      final template = <String, dynamic>{
        'type': 'AdaptiveCard',
        'body': <dynamic>[
          <String, dynamic>{'type': 'TextBlock', 'text': 'Hello'},
        ],
      };
      final file = createJsonFile('template.json', template);
      await manager.loadTemplate(file.path);

      final result = await manager.getTemplateJson();
      expect(result, isNotNull);
      expect(result!['type'], equals('AdaptiveCard'));
      expect(result['body'], isA<List<dynamic>>());
      final body = result['body'] as List<dynamic>;
      final firstItem = body.first as Map<String, dynamic>;
      expect(firstItem['text'], equals('Hello'));
    });
  });

  group('TemplateManager loadData', () {
    test('sets dataPath', () async {
      final file = createJsonFile('data.json', <String, dynamic>{
        'name': 'World',
      });
      await manager.loadData(file.path);
      expect(manager.dataPath, equals(file.path));
    });

    test('getDataJson returns parsed data', () async {
      final dataContent = <String, dynamic>{'name': 'World', 'count': 42};
      final file = createJsonFile('data.json', dataContent);
      await manager.loadData(file.path);

      final result = await manager.getDataJson();
      expect(result, isNotNull);
      expect(result!['name'], equals('World'));
      expect(result['count'], equals(42));
    });
  });

  group('TemplateManager getMergedJson', () {
    test('returns template as-is when no data is loaded', () async {
      final template = <String, dynamic>{
        'type': 'AdaptiveCard',
        'body': <dynamic>[
          <String, dynamic>{'type': 'TextBlock', 'text': 'Static text'},
        ],
      };
      final file = createJsonFile('template.json', template);
      await manager.loadTemplate(file.path);

      final result = await manager.getMergedJson();
      expect(result, isNotNull);
      final body = result!['body'] as List<dynamic>;
      final firstItem = body.first as Map<String, dynamic>;
      expect(firstItem['text'], equals('Static text'));
    });

    test('merges template with data substitutions', () async {
      final template = <String, dynamic>{
        'type': 'AdaptiveCard',
        'body': <dynamic>[
          <String, dynamic>{'type': 'TextBlock', 'text': r'${name}'},
        ],
      };
      final dataContent = <String, dynamic>{'name': 'World'};

      final tFile = createJsonFile('template.json', template);
      final dFile = createJsonFile('data.json', dataContent);
      await manager.loadTemplate(tFile.path);
      await manager.loadData(dFile.path);

      final result = await manager.getMergedJson();
      expect(result, isNotNull);
      final body = result!['body'] as List<dynamic>;
      final firstItem = body.first as Map<String, dynamic>;
      expect(firstItem['text'], equals('World'));
    });
  });

  group('TemplateManager save operations', () {
    test('saveTemplateJson returns false when no template loaded', () async {
      final result = await manager.saveTemplateJson(<String, dynamic>{
        'key': 'value',
      });
      expect(result, isFalse);
    });

    test('saveDataJson returns false when no data loaded', () async {
      final result = await manager.saveDataJson(<String, dynamic>{
        'key': 'value',
      });
      expect(result, isFalse);
    });

    test('saveTemplateJson writes to template file', () async {
      final template = <String, dynamic>{
        'type': 'AdaptiveCard',
        'body': <dynamic>[],
      };
      final file = createJsonFile('template.json', template);
      await manager.loadTemplate(file.path);

      final updated = <String, dynamic>{
        'type': 'AdaptiveCard',
        'body': <dynamic>[],
        'version': '1.5',
      };
      final result = await manager.saveTemplateJson(updated);
      expect(result, isTrue);

      // Verify file content was updated
      final savedContent =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      expect(savedContent['version'], equals('1.5'));
    });

    test('saveDataJson writes to data file', () async {
      final dataContent = <String, dynamic>{'name': 'Original'};
      final file = createJsonFile('data.json', dataContent);
      await manager.loadData(file.path);

      final updated = <String, dynamic>{'name': 'Updated', 'extra': true};
      final result = await manager.saveDataJson(updated);
      expect(result, isTrue);

      final savedContent =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      expect(savedContent['name'], equals('Updated'));
      expect(savedContent['extra'], isTrue);
    });

    test('saveJsonToPath writes to arbitrary path', () async {
      final outputPath = '${tempDir.path}/output.json';
      final content = <String, dynamic>{'type': 'AdaptiveCard', 'merged': true};

      final result = await manager.saveJsonToPath(content, outputPath);
      expect(result, isTrue);

      final savedContent =
          jsonDecode(File(outputPath).readAsStringSync())
              as Map<String, dynamic>;
      expect(savedContent['merged'], isTrue);
    });
  });

  group('TemplateManager error handling', () {
    test('getTemplateJson returns null for invalid JSON file', () async {
      final file = File('${tempDir.path}/bad.json')
        ..writeAsStringSync('not valid json {{{');
      await manager.loadTemplate(file.path);

      final result = await manager.getTemplateJson();
      expect(result, isNull);
    });

    test('getDataJson returns null for invalid JSON file', () async {
      final file = File('${tempDir.path}/bad_data.json')
        ..writeAsStringSync('not valid json');
      await manager.loadData(file.path);

      final result = await manager.getDataJson();
      expect(result, isNull);
    });

    test('getTemplateJson returns null for non-existent file', () async {
      await manager.loadTemplate('${tempDir.path}/nonexistent.json');
      final result = await manager.getTemplateJson();
      expect(result, isNull);
    });
  });
}
