import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_adaptive_template/flutter_adaptive_template.dart';

/// Manager class to handle JSON file loading, merging, and saving.
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

  /// Reads and parses the raw template JSON file.
  ///
  /// Returns null if no template file has been loaded.
  Future<Map<String, dynamic>?> getTemplateJson() async {
    if (_templateFile == null) return null;
    try {
      final content = await _templateFile!.readAsString();
      return jsonDecode(content) as Map<String, dynamic>;
    } on Exception catch (e) {
      debugPrint('Error reading template file: $e');
      return null;
    }
  }

  /// Reads and parses the raw data JSON file.
  ///
  /// Returns null if no data file has been loaded.
  Future<Map<String, dynamic>?> getDataJson() async {
    if (_dataFile == null) return null;
    try {
      final content = await _dataFile!.readAsString();
      return jsonDecode(content) as Map<String, dynamic>;
    } on Exception catch (e) {
      debugPrint('Error reading data file: $e');
      return null;
    }
  }

  /// Merges the template and data and returns the result.
  ///
  /// If no data file is selected, returns the template as is.
  /// If template file is not selected, returns null.
  Future<Map<String, dynamic>?> getMergedJson() async {
    if (_templateFile == null) return null;

    try {
      final templateContent = await _templateFile!.readAsString();
      final templateMap = jsonDecode(templateContent) as Map<String, dynamic>;

      if (_dataFile == null) {
        return templateMap;
      }

      final dataContent = await _dataFile!.readAsString();
      final dataMap = jsonDecode(dataContent) as Map<String, dynamic>;

      final resultString = AdaptiveCardTemplate(
        templateMap,
      ).expand({r'$root': dataMap, ...dataMap});
      return jsonDecode(resultString) as Map<String, dynamic>;
    } on Exception catch (e) {
      debugPrint('Error merging template: $e');
      return null;
    }
  }

  /// Saves [content] to the current template file.
  ///
  /// Returns true on success, false if no template file is loaded or an error
  /// occurs.
  Future<bool> saveTemplateJson(Map<String, dynamic> content) async {
    if (_templateFile == null) return false;
    try {
      final jsonString = const JsonEncoder.withIndent('  ').convert(content);
      await _templateFile!.writeAsString(jsonString);
      return true;
    } on Exception catch (e) {
      debugPrint('Error saving template file: $e');
      return false;
    }
  }

  /// Saves [content] to the current data file.
  ///
  /// Returns true on success, false if no data file is loaded or an error
  /// occurs.
  Future<bool> saveDataJson(Map<String, dynamic> content) async {
    if (_dataFile == null) return false;
    try {
      final jsonString = const JsonEncoder.withIndent('  ').convert(content);
      await _dataFile!.writeAsString(jsonString);
      return true;
    } on Exception catch (e) {
      debugPrint('Error saving data file: $e');
      return false;
    }
  }

  /// Saves [content] to the file at [path].
  ///
  /// Used for Save As operations (e.g., saving the merged result).
  /// Returns true on success, false on error.
  Future<bool> saveJsonToPath(Map<String, dynamic> content, String path) async {
    try {
      final jsonString = const JsonEncoder.withIndent('  ').convert(content);
      await File(path).writeAsString(jsonString);
      return true;
    } on Exception catch (e) {
      debugPrint('Error saving file to $path: $e');
      return false;
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
