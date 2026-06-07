import 'package:flutter_adaptive_cards_fs/src/utils/date_input_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseAdaptiveDateValue', () {
    test('parses yyyy-MM-dd', () {
      final dt = parseAdaptiveDateValue('2023-05-08');
      expect(dt, isNotNull);
      expect(dt!.year, 2023);
      expect(dt.month, 5);
      expect(dt.day, 8);
    });

    test('parses ISO datetime using calendar date portion only (Behavior A)', () {
      final midnightUtc = parseAdaptiveDateValue('2023-05-08T00:00:00Z');
      expect(midnightUtc, isNotNull);
      expect(midnightUtc!.year, 2023);
      expect(midnightUtc.month, 5);
      expect(midnightUtc.day, 8);

      final lateUtc = parseAdaptiveDateValue('2023-05-08T23:00:00.000Z');
      expect(lateUtc, isNotNull);
      expect(lateUtc!.year, 2023);
      expect(lateUtc.month, 5);
      expect(lateUtc.day, 8);
    });

    test('parses space-separated datetime using date portion only', () {
      final dt = parseAdaptiveDateValue('2023-05-08 14:30:00');
      expect(dt, isNotNull);
      expect(dt!.year, 2023);
      expect(dt.month, 5);
      expect(dt.day, 8);
    });

    test('returns null for invalid string', () {
      expect(parseAdaptiveDateValue('not-a-date'), isNull);
    });

    test('returns null for empty string', () {
      expect(parseAdaptiveDateValue(''), isNull);
      expect(parseAdaptiveDateValue(null), isNull);
    });
  });

  group('formatAdaptiveDateValue', () {
    test('formats as yyyy-MM-dd', () {
      expect(
        formatAdaptiveDateValue(DateTime(2023, 5, 8)),
        '2023-05-08',
      );
    });
  });
}
