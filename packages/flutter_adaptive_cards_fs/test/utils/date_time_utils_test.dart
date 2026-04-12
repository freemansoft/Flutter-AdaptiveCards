import 'package:flutter_adaptive_cards_fs/src/utils/date_time_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DateTimeUtils', () {
    test('formatText replaces DATE macros', () {
      const input =
          'Created on {{DATE(2017-02-14T06:08:39Z, SHORT)}} and {{DATE(2017-02-14T06:08:39Z)}}.';
      final output = DateTimeUtils.formatText(input);

      expect(output.contains('{{DATE'), isFalse);
      expect(
        output.contains('Feb 14'),
        isTrue,
      ); // Should contain Feb 14 regardless of locale defaults
    });

    test('formatText replaces TIME macros', () {
      const input = 'Time is {{TIME(2017-02-14T06:08:39Z)}}.';
      final output = DateTimeUtils.formatText(input);

      expect(output.contains('{{TIME'), isFalse);
    });

    test('formatText ignores malformed macros gracefully', () {
      const input = 'Not a date {{DATE(not_a_date, SHORT)}}.';
      final output = DateTimeUtils.formatText(input);

      expect(output, input); // Should gracefully fail and leave original string
    });
  });
}
