import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_plus/src/hostconfig/progress_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProgressSizesConfig', () {
    test('should deserialize correctly from JSON', () {
      final file = File('test/hostconfig/progress_sizes_config.json');
      final jsonString = file.readAsStringSync();
      final Map<String, dynamic> jsonMap =
          json.decode(jsonString) as Map<String, dynamic>;

      final config = ProgressSizesConfig.fromJson(jsonMap);

      expect(config.tiny, 12);
      expect(config.small, 22);
      expect(config.medium, 32);
      expect(config.large, 42);
      expect(config.extraLarge, 52);
      expect(config.defaultSize, 22);
    });

    test('resolveProgressSize should return correct value', () {
      final config = ProgressSizesConfig(
        tiny: 1,
        small: 2,
        medium: 3,
        large: 4,
        extraLarge: 5,
        defaultSize: 2,
      );

      expect(ProgressSizesConfig.resolveProgressSize(config, 'tiny'), 1.0);
      expect(
        ProgressSizesConfig.resolveProgressSize(config, 'extraLarge'),
        5.0,
      );
      expect(ProgressSizesConfig.resolveProgressSize(config, 'unknown'), 2.0);
    });
  });

  group('ProgressColorsConfig', () {
    test('should deserialize correctly from JSON', () {
      final file = File('test/hostconfig/progress_colors_config.json');
      final jsonString = file.readAsStringSync();
      final Map<String, dynamic> jsonMap =
          json.decode(jsonString) as Map<String, dynamic>;

      final config = ProgressColorsConfig.fromJson(jsonMap);

      expect(config.good, const Color(0xFF112233));
      expect(config.warning, const Color(0xFF445566));
      expect(config.attention, const Color(0xFF778899));
      expect(config.accent, const Color(0xFFAABBCC));
      expect(config.defaultColor, const Color(0xFFDDEEFF));
    });

    test('resolveProgressColor should return correct value', () {
      final config = ProgressColorsConfig(
        good: Colors.green,
        warning: Colors.yellow,
        attention: Colors.red,
        accent: Colors.blue,
        defaultColor: Colors.grey,
      );

      expect(
        ProgressColorsConfig.resolveProgressColor(
          config: config,
          color: 'good',
        ),
        Colors.green,
      );
      expect(
        ProgressColorsConfig.resolveProgressColor(
          config: config,
          color: 'accent',
        ),
        Colors.blue,
      );
      expect(
        ProgressColorsConfig.resolveProgressColor(
          config: config,
          color: 'unknown',
        ),
        Colors.grey,
      );
    });
  });
}
