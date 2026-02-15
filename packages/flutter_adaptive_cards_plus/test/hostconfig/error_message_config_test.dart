import 'dart:convert';
import 'dart:io';

import 'package:flutter_adaptive_cards_plus/src/hostconfig/error_message_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ErrorMessageConfig', () {
    test('should deserialize correctly from JSON', () {
      final file = File('test/hostconfig/error_message_config.json');
      final jsonString = file.readAsStringSync();
      final Map<String, dynamic> jsonMap =
          json.decode(jsonString) as Map<String, dynamic>;

      final config = ErrorMessageConfig.fromJson(jsonMap);

      expect(config.size, 'large');
      expect(config.spacing, 'extraLarge');
      expect(config.weight, 'bolder');
    });

    test('should use default values when JSON is empty', () {
      final config = ErrorMessageConfig.fromJson({});

      expect(config.size, 'default');
      expect(config.spacing, 'default');
      expect(config.weight, 'default');
    });
  });
}
