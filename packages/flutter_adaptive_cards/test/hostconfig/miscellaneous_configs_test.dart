import 'dart:convert';
import 'dart:io';

import 'package:flutter_adaptive_cards/src/hostconfig/miscellaneous_configs.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MediaConfig', () {
    test('should deserialize correctly from JSON', () {
      final file = File('test/hostconfig/media_config.json');
      final jsonString = file.readAsStringSync();
      final Map<String, dynamic> jsonMap =
          json.decode(jsonString) as Map<String, dynamic>;

      final config = MediaConfig.fromJson(jsonMap);

      expect(config.defaultPoster, 'https://example.com/poster.jpg');
      expect(config.playButton, 'https://example.com/play.png');
      expect(config.allowInlinePlayback, false);
    });
  });

  group('SeparatorConfig', () {
    test('should deserialize correctly from JSON', () {
      final file = File('test/hostconfig/separator_config.json');
      final jsonString = file.readAsStringSync();
      final Map<String, dynamic> jsonMap =
          json.decode(jsonString) as Map<String, dynamic>;

      final config = SeparatorConfig.fromJson(jsonMap);

      expect(config.lineThickness, 2);
      expect(config.lineColor, '#FF123456');
    });
  });

  group('SpacingsConfig', () {
    test('should deserialize correctly from JSON', () {
      final file = File('test/hostconfig/spacings_config.json');
      final jsonString = file.readAsStringSync();
      final Map<String, dynamic> jsonMap =
          json.decode(jsonString) as Map<String, dynamic>;

      final config = SpacingsConfig.fromJson(jsonMap);

      expect(config.small, 5);
      expect(config.defaultSpacing, 10);
      expect(config.medium, 25);
      expect(config.large, 35);
      expect(config.extraLarge, 45);
      expect(config.padding, 25);
    });

    test('resolveSpacing should return correct value', () {
      final config = SpacingsConfig(
        small: 1,
        defaultSpacing: 2,
        medium: 3,
        large: 4,
        extraLarge: 5,
        padding: 6,
      );

      expect(SpacingsConfig.resolveSpacing(config, 'small'), 1.0);
      expect(SpacingsConfig.resolveSpacing(config, 'none'), 0.0);
      expect(SpacingsConfig.resolveSpacing(config, 'medium'), 3.0);
      expect(SpacingsConfig.resolveSpacing(config, 'unknown'), 2.0);
    });
  });

  group('TextBlockConfig', () {
    test('should deserialize correctly from JSON', () {
      final file = File('test/hostconfig/text_block_config.json');
      final jsonString = file.readAsStringSync();
      final Map<String, dynamic> jsonMap =
          json.decode(jsonString) as Map<String, dynamic>;

      final config = TextBlockConfig.fromJson(jsonMap);

      expect(config.headingLevel, 3);
    });
  });
}
