import 'dart:convert';
import 'dart:io';

import 'package:flutter_adaptive_cards/src/hostconfig/adaptive_card_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AdaptiveCardConfig', () {
    test('should deserialize correctly from JSON', () {
      final file = File('test/hostconfig/adaptive_card_config.json');
      final jsonString = file.readAsStringSync();
      final Map<String, dynamic> jsonMap =
          json.decode(jsonString) as Map<String, dynamic>;

      final config = AdaptiveCardConfig.fromJson(jsonMap);

      expect(config.allowCustomStyle, false);
    });

    test('should use default values when JSON is empty', () {
      final config = AdaptiveCardConfig.fromJson({});

      expect(config.allowCustomStyle, true);
    });
  });
}
