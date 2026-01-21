import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/src/hostconfig/badge_styles_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BadgeStylesConfig', () {
    test('should deserialize correctly from JSON', () {
      final file = File('test/hostconfig/badge_styles_config.json');
      final jsonString = file.readAsStringSync();
      final Map<String, dynamic> jsonMap =
          json.decode(jsonString) as Map<String, dynamic>;

      final config = BadgeStylesConfig.fromJson(jsonMap);

      expect(
        config.filled.backgroundColors.defaultColor.defaultColor,
        const Color(0xFF111111),
      );
      expect(
        config.filled.foregroundColors.accent.defaultColor,
        const Color(0xFF222222),
      );

      expect(
        config.tint.backgroundColors.good.defaultColor,
        const Color(0xFF333333),
      );
      expect(
        config.tint.foregroundColors.warning.defaultColor,
        const Color(0xFF444444),
      );
    });

    test('should use default values when JSON is empty', () {
      final config = BadgeStylesConfig.fromJson({});

      // Testing that it doesn't crash and has some default (likely black/grey from FontColorConfig)
      expect(
        config.filled.backgroundColors.defaultColor.defaultColor,
        Colors.black,
      );
      expect(
        config.tint.foregroundColors.defaultColor.defaultColor,
        Colors.black,
      );
    });
  });
}
