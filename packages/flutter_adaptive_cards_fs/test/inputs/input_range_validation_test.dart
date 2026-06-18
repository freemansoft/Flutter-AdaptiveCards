import 'package:flutter_adaptive_cards_fs/src/cards/inputs/input_range_validation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('numberInputValueIsValid', () {
    test('value within bounds passes', () {
      expect(
        numberInputValueIsValid(value: '3', isRequired: false, min: 1, max: 5),
        isTrue,
      );
    });
    test('value above max fails', () {
      expect(
        numberInputValueIsValid(value: '99', isRequired: false, min: 1, max: 5),
        isFalse,
      );
    });
    test('value below min fails', () {
      expect(
        numberInputValueIsValid(value: '0', isRequired: false, min: 1, max: 5),
        isFalse,
      );
    });
    test('empty optional value passes', () {
      expect(
        numberInputValueIsValid(value: '', isRequired: false, min: 1, max: 5),
        isTrue,
      );
    });
    test('empty required value fails', () {
      expect(
        numberInputValueIsValid(
          value: '',
          isRequired: true,
          min: null,
          max: null,
        ),
        isFalse,
      );
    });
    test('non-numeric value fails', () {
      expect(
        numberInputValueIsValid(
          value: 'abc',
          isRequired: false,
          min: null,
          max: null,
        ),
        isFalse,
      );
    });
  });

  group('dateInputValueIsValid', () {
    test('value within bounds passes', () {
      expect(
        dateInputValueIsValid(
          value: '2026-06-17',
          isRequired: false,
          min: '2026-01-01',
          max: '2026-12-31',
        ),
        isTrue,
      );
    });
    test('value after max fails', () {
      expect(
        dateInputValueIsValid(
          value: '2027-01-01',
          isRequired: false,
          min: '2026-01-01',
          max: '2026-12-31',
        ),
        isFalse,
      );
    });
    test('value before min fails', () {
      expect(
        dateInputValueIsValid(
          value: '2025-12-31',
          isRequired: false,
          min: '2026-01-01',
          max: '2026-12-31',
        ),
        isFalse,
      );
    });
    test('empty optional value passes', () {
      expect(
        dateInputValueIsValid(
          value: '',
          isRequired: false,
          min: '2026-01-01',
          max: null,
        ),
        isTrue,
      );
    });
    test('empty required value fails', () {
      expect(
        dateInputValueIsValid(
          value: '',
          isRequired: true,
          min: null,
          max: null,
        ),
        isFalse,
      );
    });
    test('non-date value fails', () {
      expect(
        dateInputValueIsValid(
          value: 'not-a-date',
          isRequired: false,
          min: null,
          max: null,
        ),
        isFalse,
      );
    });
  });

  group('timeInputValueIsValid', () {
    test('value within bounds passes', () {
      expect(
        timeInputValueIsValid(
          value: '12:30',
          isRequired: false,
          min: '09:00',
          max: '17:00',
        ),
        isTrue,
      );
    });
    test('value after max fails', () {
      expect(
        timeInputValueIsValid(
          value: '18:00',
          isRequired: false,
          min: '09:00',
          max: '17:00',
        ),
        isFalse,
      );
    });
    test('value before min fails', () {
      expect(
        timeInputValueIsValid(
          value: '08:00',
          isRequired: false,
          min: '09:00',
          max: '17:00',
        ),
        isFalse,
      );
    });
    test('malformed time fails', () {
      expect(
        timeInputValueIsValid(
          value: '99:99',
          isRequired: false,
          min: null,
          max: null,
        ),
        isFalse,
      );
    });
    test('empty optional value passes', () {
      expect(
        timeInputValueIsValid(
          value: '',
          isRequired: false,
          min: '09:00',
          max: null,
        ),
        isTrue,
      );
    });
    test('empty required value fails', () {
      expect(
        timeInputValueIsValid(
          value: '',
          isRequired: true,
          min: null,
          max: null,
        ),
        isFalse,
      );
    });
    test('single-digit hour H:mm is valid', () {
      expect(
        timeInputValueIsValid(
          value: '9:30',
          isRequired: false,
          min: '09:00',
          max: '17:00',
        ),
        isTrue,
      );
    });
  });
}
