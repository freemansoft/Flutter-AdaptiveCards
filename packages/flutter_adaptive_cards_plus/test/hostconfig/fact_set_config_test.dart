import 'dart:convert';
import 'dart:io';

import 'package:flutter_adaptive_cards_plus/src/hostconfig/fact_set_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FactSetConfig', () {
    test('should deserialize correctly from JSON', () {
      final file = File('test/hostconfig/fact_set_config.json');
      final jsonString = file.readAsStringSync();
      final Map<String, dynamic> jsonMap =
          json.decode(jsonString) as Map<String, dynamic>;

      final config = FactSetConfig.fromJson(jsonMap);

      expect(config.title.size, 'large');
      expect(config.title.weight, 'bolder');
      expect(config.title.color, 'accent');
      expect(config.title.fontType, 'monospace');
      expect(config.title.isSubtle, true);
      expect(config.title.wrap, false);
      expect(config.title.maxWidth, 200);

      expect(config.value.size, 'small');
      expect(config.value.weight, 'lighter');
      expect(config.value.color, 'good');
      expect(config.value.fontType, 'default');
      expect(config.value.isSubtle, false);
      expect(config.value.wrap, true);
      expect(config.value.maxWidth, 100);

      expect(config.spacing, 15);
    });

    test('should use default values when JSON is empty', () {
      final config = FactSetConfig.fromJson({});

      expect(config.title.weight, 'bolder');
      expect(config.title.maxWidth, 150);
      expect(config.value.weight, 'default');
      expect(config.value.maxWidth, 0);
      expect(config.spacing, 10);
    });
  });
}
