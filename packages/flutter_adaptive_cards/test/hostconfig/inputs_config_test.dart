import 'dart:convert';
import 'dart:io';

import 'package:flutter_adaptive_cards/src/hostconfig/inputs_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InputsConfig', () {
    test('should deserialize correctly from JSON', () {
      final file = File('test/hostconfig/inputs_config.json');
      final jsonString = file.readAsStringSync();
      final Map<String, dynamic> jsonMap =
          json.decode(jsonString) as Map<String, dynamic>;

      final config = InputsConfig.fromJson(jsonMap);

      expect(config.label.inputSpacing, 'large');
      expect(config.label.requiredInputs.color, 'attention');
      expect(config.label.requiredInputs.isSubtle, true);
      expect(config.label.requiredInputs.suffix, '*');

      expect(config.label.optionalInputs.color, 'good');
      expect(config.label.optionalInputs.suffix, ' (optional)');

      expect(config.errorMessage.size, 'medium');
      expect(config.errorMessage.spacing, 'small');
    });

    test('should use default values when JSON is empty', () {
      final config = InputsConfig.fromJson({});

      expect(config.label.inputSpacing, 'default');
      expect(config.label.requiredInputs.color, 'default');
      expect(config.errorMessage.size, 'default');
    });
  });
}
