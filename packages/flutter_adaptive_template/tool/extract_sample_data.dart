import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

void main() {
  final dir = Directory(
    'packages/flutter_adaptive_template/test/ms_template_examples',
  );
  if (!dir.existsSync()) {
    print('Directory not found: ${dir.path}');
    return;
  }

  final files = dir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.json'));

  for (final file in files) {
    if (file.path.endsWith('_data.json')) continue; // Skip existing data files

    try {
      final content = file.readAsStringSync();
      final jsonMap = json.decode(content);

      if (jsonMap is Map<String, dynamic> &&
          jsonMap.containsKey(r'$sampleData')) {
        final sampleData = jsonMap[r'$sampleData'];

        // Remove from template
        jsonMap.remove(r'$sampleData');

        // Write back template
        const encoder = JsonEncoder.withIndent('  ');
        file.writeAsStringSync(encoder.convert(jsonMap));

        // Write data file
        final extension = p.extension(file.path);
        final nameWithoutExt = p.basenameWithoutExtension(file.path);
        final directory = p.dirname(file.path);
        final dataFilePath = p.join(
          directory,
          '${nameWithoutExt}_data$extension',
        );

        File(dataFilePath).writeAsStringSync(encoder.convert(sampleData));

        debugPrint('Processed: ${file.path} -> Created: $dataFilePath');
      }
    } catch (e) {
      debugPrint('Error processing ${file.path}: $e');
    }
  }
}
