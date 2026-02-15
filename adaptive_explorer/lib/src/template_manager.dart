import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_adaptive_template/flutter_adaptive_template.dart';

/// Manager class to handle JSON file loading and merging.
class TemplateManager {
  File? _templateFile;
  File? _dataFile;

  /// Loads the template from the file at [path].
  Future<void> loadTemplate(String path) async {
    _templateFile = File(path);
  }

  /// Loads the data from the file at [path].
  Future<void> loadData(String path) async {
    _dataFile = File(path);
  }

  /// Merges the template and data.
  ///
  /// If no data file is selected, returns the template as is.
  /// If template file is not selected, returns null.
  Future<Map<String, dynamic>?> getMergedTemplate() async {
    if (_templateFile == null) return null;

    try {
      final templateContent = await _templateFile!.readAsString();
      final templateMap = jsonDecode(templateContent) as Map<String, dynamic>;

      if (_dataFile == null) {
        return templateMap;
      }

      final dataContent = await _dataFile!.readAsString();
      final dataMap = jsonDecode(dataContent) as Map<String, dynamic>;

      final resultString = AdaptiveCardTemplate(templateMap).expand({
        r'$root': dataMap,
        ...dataMap,
      });
      return jsonDecode(resultString) as Map<String, dynamic>;
    } on Exception catch (e) {
      debugPrint('Error merging template: $e');
      return null;
    }
  }

  /// Returns the path of the currently loaded template file.
  String? get templatePath => _templateFile?.path;

  /// Returns the path of the currently loaded data file.
  String? get dataPath => _dataFile?.path;

  /// Returns the currently loaded template file object.
  File? get templateFile => _templateFile;

  /// Returns the currently loaded data file object.
  File? get dataFile => _dataFile;
}
