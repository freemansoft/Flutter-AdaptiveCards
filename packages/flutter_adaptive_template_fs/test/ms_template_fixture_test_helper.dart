import 'dart:convert';
import 'dart:io';

import 'package:flutter_adaptive_template_fs/flutter_adaptive_template_fs.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// Validates all `*_data.json` fixtures under [fixtureDirectory].
void registerMicrosoftTemplateFixtureTests({
  required String fixtureDirectory,
  required String groupName,
}) {
  final dir = Directory(fixtureDirectory);
  if (!dir.existsSync()) {
    return;
  }

  final dataFiles = dir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('_data.json'));

  group(groupName, () {
    for (final dataFile in dataFiles) {
      final baseName = p
          .basenameWithoutExtension(dataFile.path)
          .replaceAll('_data', '');

      test('Example: $baseName', () {
        final templatePath = dataFile.path.replaceAll(
          '_data.json',
          '_template.json',
        );
        final templateFile = File(templatePath);
        if (!templateFile.existsSync()) {
          fail('Template file not found: $templatePath');
        }
        final templateJson = json.decode(templateFile.readAsStringSync());

        final dataJson = json.decode(dataFile.readAsStringSync());

        final outputPath = dataFile.path.replaceAll(
          '_data.json',
          '_output.json',
        );
        final outputFile = File(outputPath);
        if (!outputFile.existsSync()) {
          fail(
            'Expected output file not found: $outputPath. '
            'Please run tool/generate_example_outputs.dart first.',
          );
        }
        final expectedJson = json.decode(outputFile.readAsStringSync());

        final template = AdaptiveCardTemplate(
          templateJson as Map<String, dynamic>,
        );
        final result = template.expand(dataJson as Map<String, dynamic>);
        final resultJson = json.decode(result);

        expect(resultJson, equals(expectedJson));
      });
    }
  });
}
