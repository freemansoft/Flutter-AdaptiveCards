import 'dart:convert';
import 'dart:io';

import 'package:flutter_adaptive_cards_plus/src/hostconfig/image_sizes_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ImageSizesConfig', () {
    test('should deserialize correctly from JSON', () {
      final file = File('test/hostconfig/image_sizes_config.json');
      final jsonString = file.readAsStringSync();
      final Map<String, dynamic> jsonMap =
          json.decode(jsonString) as Map<String, dynamic>;

      final config = ImageSizesConfig.fromJson(jsonMap);

      expect(config.small, 40);
      expect(config.medium, 80);
      expect(config.large, 160);
    });

    test('should use default values when JSON is empty', () {
      final config = ImageSizesConfig.fromJson({});

      expect(config.small, 80);
      expect(config.medium, 120);
      expect(config.large, 180);
    });

    test('resolveImageSizes should return correct size', () {
      final config = ImageSizesConfig(small: 10, medium: 20, large: 30);

      expect(ImageSizesConfig.resolveImageSizes(config, 'small'), 10);
      expect(ImageSizesConfig.resolveImageSizes(config, 'medium'), 20);
      expect(ImageSizesConfig.resolveImageSizes(config, 'LARGE'), 30);
      expect(ImageSizesConfig.resolveImageSizes(config, 'unknown'), 20);
    });
  });
}
