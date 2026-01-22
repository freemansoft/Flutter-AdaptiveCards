import 'dart:convert';
import 'dart:io';

import 'package:flutter_adaptive_template/flutter_adaptive_template.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  final dir = Directory('test/microsoft_template_examples');
  if (!dir.existsSync()) {
    // If not running from package root, might be nested?
    // Usually flutter test runs from package root.
    return;
  }

  // Find all data files
  final dataFiles = dir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('_data.json'));

  group('Validate Microsoft Template Examples', () {
    for (final dataFile in dataFiles) {
      final baseName = p
          .basenameWithoutExtension(dataFile.path)
          .replaceAll('_data', '');

      test('Example: $baseName', () {
        // 1. Template
        final templatePath = dataFile.path.replaceAll('_data.json', '.json');
        final templateFile = File(templatePath);
        if (!templateFile.existsSync()) {
          fail('Template file not found: $templatePath');
        }
        final templateJson = json.decode(templateFile.readAsStringSync());

        // 2. Data
        final dataJson = json.decode(dataFile.readAsStringSync());

        // 3. Expected Output
        final outputPath = dataFile.path.replaceAll(
          '_data.json',
          '_output.json',
        );
        final outputFile = File(outputPath);
        if (!outputFile.existsSync()) {
          fail(
            'Expected output file not found: $outputPath. Please run tool/generate_example_outputs.dart first.',
          );
        }
        final expectedJson = json.decode(outputFile.readAsStringSync());

        // 4. Verification
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
