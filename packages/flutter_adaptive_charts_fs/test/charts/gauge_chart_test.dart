import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_adaptive_charts_fs/src/charts/gauge_painter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

void main() {
  group('normalizeGaugeValue', () {
    test('maps value between min and max to fraction', () {
      expect(normalizeGaugeValue(50, 0, 100), 0.5);
      expect(normalizeGaugeValue(0, 0, 100), 0);
      expect(normalizeGaugeValue(100, 0, 100), 1);
    });

    test('clamps out-of-range values', () {
      expect(normalizeGaugeValue(-10, 0, 100), 0);
      expect(normalizeGaugeValue(150, 0, 100), 1);
    });
  });

  group('gaugeFractionToAngle', () {
    test('sweeps from pi to 2*pi across the semicircle', () {
      expect(gaugeFractionToAngle(0), math.pi);
      expect(gaugeFractionToAngle(0.5), closeTo(math.pi * 1.5, 0.001));
      expect(gaugeFractionToAngle(1), closeTo(math.pi * 2, 0.001));
    });
  });

  group('formatGaugeValue', () {
    test('formats percentage and fraction', () {
      expect(
        formatGaugeValue(
          value: 75,
          min: 0,
          max: 100,
          format: GaugeValueFormat.percentage,
        ),
        '75%',
      );
      expect(
        formatGaugeValue(
          value: 75,
          min: 0,
          max: 100,
          format: GaugeValueFormat.fraction,
        ),
        '75/100',
      );
    });
  });

  testWidgets('renders gauge with title, value, legend, and CustomPaint', (
    tester,
  ) async {
    const key = ValueKey('gauge');
    await tester.pumpWidget(
      getTestWidgetFromString(
        key: key,
        jsonString: '''
{
  "type": "AdaptiveCard",
  "version": "1.6",
  "body": [
    {
      "type": "Chart.Gauge",
      "title": "Performance",
      "subLabel": "Q1 target",
      "min": 0,
      "max": 100,
      "value": 75,
      "valueFormat": "Percentage",
      "showLegend": true,
      "showMinMax": true,
      "segments": [
        { "color": "#FF0000", "value": 50, "legend": "Low" },
        { "color": "#00FF00", "value": 50, "legend": "High" }
      ]
    }
  ]
}
''',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Performance'), findsOneWidget);
    expect(find.text('Low'), findsOneWidget);
    expect(find.text('High'), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
  });

  testWidgets('value arc position matches value between min and max', (
    tester,
  ) async {
    const min = 0.0;
    const max = 200.0;
    const value = 100.0;

    final fraction = normalizeGaugeValue(value, min, max);
    expect(fraction, 0.5);

    final angle = gaugeFractionToAngle(fraction);
    expect(angle, closeTo(math.pi * 1.5, 0.001));
  });
}
