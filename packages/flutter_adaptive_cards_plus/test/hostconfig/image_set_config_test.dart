import 'dart:convert';
import 'dart:io';

import 'package:flutter_adaptive_cards_plus/src/hostconfig/image_set_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ImageSetConfig', () {
    test('should deserialize correctly from JSON', () {
      final file = File('test/hostconfig/image_set_config.json');
      final jsonString = file.readAsStringSync();
      final Map<String, dynamic> jsonMap =
          json.decode(jsonString) as Map<String, dynamic>;

      final config = ImageSetConfig.fromJson(jsonMap);

      expect(config.imageSizeSmall, 50);
      expect(config.imageSizeMedium, 70);
      expect(config.imageSizeLarge, 90);
    });

    test('should use default values when JSON is empty', () {
      final config = ImageSetConfig.fromJson({});

      expect(config.imageSizeSmall, 64);
      expect(config.imageSizeMedium, 64);
      expect(config.imageSizeLarge, 64);
    });

    test('imageSize should return correct size based on description', () {
      final config = ImageSetConfig(
        imageSizeSmall: 10,
        imageSizeMedium: 20,
        imageSizeLarge: 30,
      );

      expect(config.imageSize('small'), 10);
      expect(config.imageSize('MEDIUM'), 20);
      expect(config.imageSize('large'), 30);
      expect(config.imageSize('unknown'), 20);
    });
  });
}
