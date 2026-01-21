import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter_adaptive_cards/src/hostconfig/font_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FontSizesConfig', () {
    test('should deserialize correctly from JSON', () {
      final file = File('test/hostconfig/font_sizes_config.json');
      final jsonString = file.readAsStringSync();
      final Map<String, dynamic> jsonMap =
          json.decode(jsonString) as Map<String, dynamic>;

      final config = FontSizesConfig.fromJson(jsonMap);

      expect(config.small, 8);
      expect(config.defaultSize, 11);
      expect(config.medium, 13);
      expect(config.large, 16);
      expect(config.extraLarge, 19);
    });

    test('should use default values when JSON is empty', () {
      final config = FontSizesConfig.fromJson({});

      expect(config.small, 10);
      expect(config.defaultSize, 12);
    });
  });

  group('FontWeightsConfig', () {
    test('should deserialize correctly from JSON', () {
      final file = File('test/hostconfig/font_weights_config.json');
      final jsonString = file.readAsStringSync();
      final Map<String, dynamic> jsonMap =
          json.decode(jsonString) as Map<String, dynamic>;

      final config = FontWeightsConfig.fromJson(jsonMap);

      expect(config.lighter, 100);
      expect(config.defaultWeight, 300);
      expect(config.bolder, 700);
    });

    test('should use default values when JSON is empty', () {
      final config = FontWeightsConfig.fromJson({});

      expect(config.lighter, FontWeight.w200.value);
      expect(config.defaultWeight, FontWeight.normal.value);
    });
  });
}
