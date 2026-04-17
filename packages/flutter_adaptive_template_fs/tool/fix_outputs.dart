import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_adaptive_template_fs/src/template.dart';

void fixExample(String name) {
  final dataPath = 'test/ms_template_examples/${name}_data.json';
  final templatePath = 'test/ms_template_examples/${name}_template.json';
  final outputPath = 'test/ms_template_examples/${name}_output.json';

  final dataStr = File(dataPath).readAsStringSync();
  final templateStr = File(templatePath).readAsStringSync();

  final template = AdaptiveCardTemplate(
    jsonDecode(templateStr) as Map<String, dynamic>,
  );
  final expanded = template.expand(jsonDecode(dataStr) as Map<String, dynamic>);

  final formatted = const JsonEncoder.withIndent(
    '  ',
  ).convert(jsonDecode(expanded));
  File(outputPath).writeAsStringSync('$formatted\n');
  debugPrint('Fixed $name');
}

void main() {
  fixExample('graph.microsoft.com/Users');
  fixExample('ogp.me/OpenGraph');
}
