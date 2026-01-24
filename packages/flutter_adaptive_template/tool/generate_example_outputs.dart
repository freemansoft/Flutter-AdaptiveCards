import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_adaptive_template/flutter_adaptive_template.dart';

void main() {
  final directories = [
    Directory('test/ms_template_examples'),
    Directory('test/ms_template_samples'),
  ];

  for (final dir in directories) {
    if (!dir.existsSync()) {
      debugPrint('Directory not found: ${dir.path}');
      continue;
    }
    debugPrint('Processing directory: ${dir.path}');

    final dataFiles = dir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('_data.json'));

    for (final dataFile in dataFiles) {
      if (dataFile.path.endsWith('_output.json')) continue;

      final templatePath = dataFile.path.replaceAll(
        '_data.json',
        '_template.json',
      );
      final templateFile = File(templatePath);

      if (!templateFile.existsSync()) {
        debugPrint('Template not found for ${dataFile.path}');
        continue;
      }

      try {
        final templateJson = json.decode(templateFile.readAsStringSync());
        final dataJson = json.decode(dataFile.readAsStringSync());

        final template = AdaptiveCardTemplate(
          templateJson as Map<String, dynamic>,
        );
        final result = template.expand(dataJson as Map<String, dynamic>);

        // Formatting the result to be readable
        final resultJson = json.decode(result);
        const encoder = JsonEncoder.withIndent('  ');
        final outputContent = encoder.convert(resultJson);

        final outputPath = dataFile.path.replaceAll(
          '_data.json',
          '_output.json',
        );
        File(outputPath).writeAsStringSync(outputContent);

        debugPrint('Generated output: $outputPath');
      } catch (e) {
        debugPrint('Error processing ${dataFile.path}: $e');
        debugPrint(e.toString());
      }
    }
  }
}
