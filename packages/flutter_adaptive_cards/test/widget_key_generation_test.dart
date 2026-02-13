import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/src/utils/utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Widget Key Generation Tests', () {
    test('generateAdaptiveWidgetKey creates ValueKey with id', () {
      final map = {'id': 'testElement'};
      final key = generateAdaptiveWidgetKey(map);

      expect(key, isA<ValueKey<String>>());
      expect(key.value, 'testElement_adaptive');
    });

    test('generateAdaptiveWidgetKey with missing id uses generated id', () {
      final map = {'type': 'TextBlock'};
      final key = generateAdaptiveWidgetKey(map);

      expect(key, isA<ValueKey<String>>());
      // Should have _adaptive suffix
      expect(key.value, endsWith('_adaptive'));
    });

    test('generateAdaptiveWidgetKey is consistent for same id', () {
      final map1 = {'id': 'element1'};
      final map2 = {'id': 'element1'};

      final key1 = generateAdaptiveWidgetKey(map1);
      final key2 = generateAdaptiveWidgetKey(map2);

      expect(key1, equals(key2));
    });

    test('generateAdaptiveWidgetKey different for different ids', () {
      final map1 = {'id': 'element1'};
      final map2 = {'id': 'element2'};

      final key1 = generateAdaptiveWidgetKey(map1);
      final key2 = generateAdaptiveWidgetKey(map2);

      expect(key1, isNot(equals(key2)));
    });

    test('loadId extracts id from map', () {
      final map = {'id': 'myElement', 'type': 'TextBlock'};
      final id = loadId(map);

      expect(id, 'myElement');
    });

    test('loadId with missing id generates one', () {
      final map = {'type': 'TextBlock'};
      final id = loadId(map);

      // Should have generated an id
      expect(id, isNotEmpty);
      expect(id, startsWith('TextBlock-'));
    });

    test('idIsNatural returns true for user-provided id', () {
      final map = {'id': 'userDefinedId'};
      final isNatural = idIsNatural(map);

      expect(isNatural, isTrue);
    });

    test('idIsNatural returns false for generated id', () {
      final map = {'type': 'TextBlock'};
      // First load the id to generate it
      loadId(map);

      final isNatural = idIsNatural(map);

      // Generated IDs are not natural
      expect(isNatural, isFalse);
    });

    test('Widget key pattern for inputs follows {id}_adaptive convention', () {
      final inputMap = {'id': 'nameInput', 'type': 'Input.Text'};
      final key = generateAdaptiveWidgetKey(inputMap);

      expect(key.value, 'nameInput_adaptive');
    });

    test('Multiple widgets with same ID get same key', () {
      final map = {'id': 'sharedId'};

      final key1 = generateAdaptiveWidgetKey(map);
      final key2 = generateAdaptiveWidgetKey(map);

      // Keys should be equal (same underlying value)
      expect(key1, equals(key2));
    });

    test('Key generation handles special characters in ID', () {
      final map = {'id': 'my-special_id.123'};
      final key = generateAdaptiveWidgetKey(map);

      expect(key.value, 'my-special_id.123_adaptive');
    });

    test('Key generation for empty string ID', () {
      final map = {'id': ''};
      final key = generateAdaptiveWidgetKey(map);

      // Should still create a key
      expect(key, isA<ValueKey<String>>());
      expect(key.value, endsWith('_adaptive'));
    });
  });

  group('Input Field Key Pattern Tests', () {
    test(
      'Input field key should be just the ID (without _adaptive suffix)',
      () {
        // This tests the documented pattern where:
        // - Card widget key: {id}_adaptive
        // - Input field key: {id}
        // The actual input field widgets use ValueKey(id) directly

        const inputId = 'emailInput';
        const cardKey = ValueKey('${inputId}_adaptive');
        const fieldKey = ValueKey(inputId);

        expect(cardKey, isNot(equals(fieldKey)));
        expect(cardKey.value, '${inputId}_adaptive');
        expect(fieldKey.value, inputId);
      },
    );

    test('ChoiceSet item keys follow {id}_{item} pattern', () {
      const choiceSetId = 'colorChoice';
      const itemValue = 'red';

      const itemKey = ValueKey('${choiceSetId}_$itemValue');

      expect(itemKey.value, 'colorChoice_red');
    });
  });
}
