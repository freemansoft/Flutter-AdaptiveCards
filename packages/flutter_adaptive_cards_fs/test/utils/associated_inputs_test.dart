import 'package:flutter_adaptive_cards_fs/src/utils/associated_inputs.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('shouldMergeAssociatedInputs', () {
    test('null defaults to true', () {
      expect(shouldMergeAssociatedInputs(null), isTrue);
    });

    test('auto returns true', () {
      expect(shouldMergeAssociatedInputs('auto'), isTrue);
    });

    test('none returns false', () {
      expect(shouldMergeAssociatedInputs('none'), isFalse);
    });
  });

  group('mergeSiblingInputParameters', () {
    test('excludes firing input id', () {
      final result = mergeSiblingInputParameters(
        siblingValues: {
          'inputA': 'valueA',
          'inputB': 'valueB',
        },
        excludeInputId: 'inputA',
      );

      expect(result, {'inputB': 'valueB'});
    });

    test('preserves existing author parameters', () {
      final result = mergeSiblingInputParameters(
        siblingValues: {
          'inputA': 'valueA',
          'inputB': 'valueB',
        },
        excludeInputId: 'inputA',
        existingParameters: {
          'authorKey': 'authorValue',
        },
      );

      expect(
        result,
        {
          'authorKey': 'authorValue',
          'inputB': 'valueB',
        },
      );
    });
  });

  group('mergeActionData', () {
    test('none returns action data only', () {
      final result = mergeActionData(
        actionData: {'actionKey': 'actionValue'},
        inputValues: {'inputKey': 'inputValue'},
        associatedInputs: 'none',
      );

      expect(result, {'actionKey': 'actionValue'});
    });

    test('auto merges input values over action keys', () {
      final result = mergeActionData(
        actionData: {
          'sharedKey': 'actionValue',
          'actionOnly': 'actionOnly',
        },
        inputValues: {
          'sharedKey': 'inputValue',
          'inputOnly': 'inputOnly',
        },
        associatedInputs: 'auto',
      );

      expect(
        result,
        {
          'sharedKey': 'inputValue',
          'actionOnly': 'actionOnly',
          'inputOnly': 'inputOnly',
        },
      );
    });
  });
}
