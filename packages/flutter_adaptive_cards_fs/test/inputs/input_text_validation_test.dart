import 'package:flutter_adaptive_cards_fs/src/cards/inputs/input_text_validation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// Matches ac-qv-event.json phone field regex.
  const phonePattern = r'^\(\d{3}\) \d{3}-\d{4}$';

  group('textInputValueIsValid', () {
    test('empty required value fails', () {
      expect(
        textInputValueIsValid(
          value: '',
          isRequired: true,
          regexPattern: phonePattern,
        ),
        isFalse,
      );
    });

    test('empty optional value passes when regex present', () {
      expect(
        textInputValueIsValid(
          value: '',
          isRequired: false,
          regexPattern: phonePattern,
        ),
        isTrue,
      );
    });

    test('phone pattern accepts formatted number', () {
      expect(
        textInputValueIsValid(
          value: '(123) 456-7890',
          isRequired: true,
          regexPattern: phonePattern,
        ),
        isTrue,
      );
    });

    test('phone pattern rejects AAA', () {
      expect(
        textInputValueIsValid(
          value: 'AAA',
          isRequired: true,
          regexPattern: phonePattern,
        ),
        isFalse,
      );
    });

    test('invalid regex pattern does not fail validation', () {
      expect(
        textInputValueIsValid(
          value: 'anything',
          isRequired: false,
          regexPattern: '([invalid',
        ),
        isTrue,
      );
    });
  });
}
