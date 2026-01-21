import 'dart:convert';
import 'dart:io';

import 'package:flutter_adaptive_cards/src/hostconfig/text_style_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TextStylesConfig', () {
    test('should deserialize correctly from JSON', () {
      final file = File('test/hostconfig/text_styles_config.json');
      final jsonString = file.readAsStringSync();
      final Map<String, dynamic> jsonMap =
          json.decode(jsonString) as Map<String, dynamic>;

      final config = TextStylesConfig.fromJson(jsonMap);

      expect(config.heading.weight, 'bolder');
      expect(config.heading.size, 'extraLarge');
      expect(config.heading.color, 'accent');

      expect(config.columnHeader.weight, 'normal');
      expect(config.columnHeader.size, 'medium');
      expect(config.columnHeader.isSubtle, true);
      expect(config.columnHeader.fontType, 'monospace');
    });

    test('should use default values when JSON is empty', () {
      final config = TextStylesConfig.fromJson({});

      expect(config.heading.weight, 'bolder');
      expect(config.heading.size, 'large');
      expect(config.columnHeader.weight, 'bolder');
    });
  });
}
