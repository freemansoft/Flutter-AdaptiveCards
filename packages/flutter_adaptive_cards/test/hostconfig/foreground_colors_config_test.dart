import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/src/hostconfig/foreground_colors_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ForegroundColorsConfig', () {
    test('should deserialize correctly from JSON', () {
      final file = File('test/hostconfig/foreground_colors_config.json');
      final jsonString = file.readAsStringSync();
      final Map<String, dynamic> jsonMap =
          json.decode(jsonString) as Map<String, dynamic>;

      final config = ForegroundColorsConfig.fromJson(jsonMap);

      expect(config.defaultColor.defaultColor, const Color(0xFF111111));
      expect(config.accent.defaultColor, const Color(0xFF222222));
      expect(config.dark.defaultColor, const Color(0xFF333333));
      expect(config.light.defaultColor, const Color(0xFF444444));
      expect(config.good.defaultColor, const Color(0xFF555555));
      expect(config.warning.defaultColor, const Color(0xFF666666));
      expect(config.attention.defaultColor, const Color(0xFF777777));
    });

    test('should use default values when JSON is empty', () {
      final config = ForegroundColorsConfig.fromJson({});

      expect(config.defaultColor.defaultColor, const Color(0xFF000000));
      expect(config.accent.defaultColor, const Color(0xFF0000FF));
    });

    test('fontColorConfig should return correct color config', () {
      final config = ForegroundColorsConfig.fromJson({});

      expect(config.fontColorConfig('accent'), config.accent);
      expect(config.fontColorConfig('GOOD'), config.good);
      expect(config.fontColorConfig('unknown'), config.defaultColor);
      expect(config.fontColorConfig(null), config.defaultColor);
    });
  });
}
