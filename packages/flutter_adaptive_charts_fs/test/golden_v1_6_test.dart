import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'utils/test_utils.dart';

/// Golden tests use a taller viewport to fit chart chrome (title, axis names, legend).
const Size kChartGoldenTestViewSize = Size(500, 800);

void main() {
  testWidgets('Golden Donut', (tester) async {
    configureTestView(size: kChartGoldenTestViewSize);
    const ValueKey key = ValueKey('paint');
    final Widget sample = getChartSampleForGoldenTest(key, 'chart_donut');
    await tester.pumpWidget(sample);
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(key),
      matchesGoldenFile(getGoldenPath('v1_6_donut.png')),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }, tags: ['golden']);

  testWidgets('Vertical Bar Chart', (tester) async {
    configureTestView(size: kChartGoldenTestViewSize);
    const ValueKey key = ValueKey('paint');
    final Widget sample = getChartSampleForGoldenTest(
      key,
      'chart_vertical_bar',
    );
    await tester.pumpWidget(sample);
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(key),
      matchesGoldenFile(getGoldenPath('v1_6_vertical_bar.png')),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }, tags: ['golden']);

  testWidgets('Horizontal Bar Chart', (tester) async {
    configureTestView(size: kChartGoldenTestViewSize);
    const ValueKey key = ValueKey('paint');
    final Widget sample = getChartSampleForGoldenTest(
      key,
      'chart_horizontal_bar',
    );
    await tester.pumpWidget(sample);
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(key),
      matchesGoldenFile(getGoldenPath('v1_6_horizontal_bar.png')),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }, tags: ['golden']);

  testWidgets('Vertical Bar Grouped Chart', (tester) async {
    configureTestView(size: kChartGoldenTestViewSize);
    const ValueKey key = ValueKey('paint');
    final Widget sample = getChartSampleForGoldenTest(
      key,
      'chart_bar_vertical_grouped',
    );
    await tester.pumpWidget(sample);
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(key),
      matchesGoldenFile(getGoldenPath('v1_6_vertical_bar_grouped.png')),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }, tags: ['golden']);

  testWidgets('Horizontal Bar Stacked Chart', (tester) async {
    configureTestView(size: kChartGoldenTestViewSize);
    const ValueKey key = ValueKey('paint');
    final Widget sample = getChartSampleForGoldenTest(
      key,
      'chart_bar_horizontal_stacked',
    );
    await tester.pumpWidget(sample);
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(key),
      matchesGoldenFile(getGoldenPath('v1_6_horizontal_bar_stacked.png')),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }, tags: ['golden']);

  testWidgets('Line Chart', (tester) async {
    configureTestView(size: kChartGoldenTestViewSize);
    const ValueKey key = ValueKey('paint');
    final Widget sample = getChartSampleForGoldenTest(key, 'chart_line');
    await tester.pumpWidget(sample);
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(key),
      matchesGoldenFile(getGoldenPath('v1_6_line.png')),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }, tags: ['golden']);

  testWidgets('Pie Chart', (tester) async {
    configureTestView(size: kChartGoldenTestViewSize);
    const ValueKey key = ValueKey('paint');
    final Widget sample = getChartSampleForGoldenTest(key, 'chart_pie');
    await tester.pumpWidget(sample);
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(key),
      matchesGoldenFile(getGoldenPath('v1_6_pie.png')),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }, tags: ['golden']);

  testWidgets('Gauge Chart', (tester) async {
    configureTestView(size: kChartGoldenTestViewSize);
    const ValueKey key = ValueKey('paint');
    final Widget sample = getChartSampleForGoldenTest(key, 'chart_gauge');
    await tester.pumpWidget(sample);
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(key),
      matchesGoldenFile(getGoldenPath('v1_6_gauge.png')),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }, tags: ['golden']);
}
