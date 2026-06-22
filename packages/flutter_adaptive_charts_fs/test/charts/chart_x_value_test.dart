import 'package:flutter_adaptive_charts_fs/src/charts/chart_x_value.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseChartXValue', () {
    test('passes numeric values through', () {
      expect(parseChartXValue(3), 3.0);
      expect(parseChartXValue(2.5), 2.5);
    });

    test('parses ISO datetime to epoch milliseconds', () {
      final expected = DateTime.parse('2026-06-17T00:00:00Z')
          .millisecondsSinceEpoch
          .toDouble();
      expect(parseChartXValue('2026-06-17T00:00:00Z'), expected);
    });

    test('parses ISO date to epoch milliseconds', () {
      final expected =
          DateTime.parse('2026-06-17').millisecondsSinceEpoch.toDouble();
      expect(parseChartXValue('2026-06-17'), expected);
    });

    test('returns 0.0 for unparseable values', () {
      expect(parseChartXValue('not-a-date'), 0.0);
      expect(parseChartXValue(null), 0.0);
    });
  });
}
