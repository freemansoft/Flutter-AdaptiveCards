import 'package:flutter/widgets.dart';
import 'package:flutter_adaptive_cards_fs/src/cards/containers/table_column_width.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // NOTE: TableColumnWidth subclasses do NOT override `==`, so assert on the
  // runtime type and the public `value` field rather than instance equality.
  Matcher isFlex(double value) =>
      isA<FlexColumnWidth>().having((w) => w.value, 'value', value);

  group('mapColumnWidth', () {
    test('"auto" maps to IntrinsicColumnWidth', () {
      expect(mapColumnWidth('auto'), isA<IntrinsicColumnWidth>());
    });

    test('"AUTO" is case-insensitive', () {
      expect(mapColumnWidth('AUTO'), isA<IntrinsicColumnWidth>());
    });

    test('"stretch" maps to flex 1', () {
      expect(mapColumnWidth('stretch'), isFlex(1));
    });

    test('positive number maps to flex weight', () {
      expect(mapColumnWidth(3), isFlex(3));
      expect(mapColumnWidth(2.5), isFlex(2.5));
    });

    test('zero or negative number falls back to flex 1', () {
      expect(mapColumnWidth(0), isFlex(1));
      expect(mapColumnWidth(-4), isFlex(1));
    });

    test('"Npx" maps to FixedColumnWidth', () {
      expect(
        mapColumnWidth('50px'),
        isA<FixedColumnWidth>().having((w) => w.value, 'value', 50.0),
      );
    });

    test('unparseable px falls back to flex 1', () {
      expect(mapColumnWidth('abcpx'), isFlex(1));
    });

    test('null and unknown strings fall back to flex 1', () {
      expect(mapColumnWidth(null), isFlex(1));
      expect(mapColumnWidth('weird'), isFlex(1));
    });
  });

  group('parseCellMinHeightPx', () {
    test('parses "80px"', () {
      expect(parseCellMinHeightPx('80px'), 80.0);
    });

    test('parses a bare number string', () {
      expect(parseCellMinHeightPx('120'), 120.0);
    });

    test('returns null for null, empty, or non-positive', () {
      expect(parseCellMinHeightPx(null), isNull);
      expect(parseCellMinHeightPx('abc'), isNull);
      expect(parseCellMinHeightPx('0px'), isNull);
      expect(parseCellMinHeightPx('-5px'), isNull);
    });
  });
}
