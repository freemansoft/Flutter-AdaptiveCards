import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'utils/test_utils.dart';

// Helper to load widget from our v1.6 samples
Widget getSampleForGoldenTest(Key key, String sampleName) {
  // getWidget expects path relative to test/samples/
  return getTestWidgetFromPath(path: 'v1.6/$sampleName.json', key: key);
}

void configureTestView() {
  RendererBinding.instance.renderViews.first.configuration =
      TestViewConfiguration.fromView(
        size: const Size(500, 700),
        view: PlatformDispatcher.instance.implicitView!,
      );
}

void main() {
  testWidgets('Golden Donut', (tester) async {
    configureTestView();
    const ValueKey key = ValueKey('paint');
    final Widget sample = getSampleForGoldenTest(key, 'chart_donut');
    await tester.pumpWidget(sample);
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(key),
      matchesGoldenFile('gold_files/v1_6_donut.png'),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }, tags: ['golden']);

  testWidgets('Vertical Bar Chart', (tester) async {
    configureTestView();
    const ValueKey key = ValueKey('paint');
    final Widget sample = getSampleForGoldenTest(key, 'chart_bar');
    await tester.pumpWidget(sample);
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(key),
      matchesGoldenFile('gold_files/v1_6_bar.png'),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }, tags: ['golden']);

  testWidgets('Line Chart', (tester) async {
    configureTestView();
    const ValueKey key = ValueKey('paint');
    final Widget sample = getSampleForGoldenTest(key, 'chart_line');
    await tester.pumpWidget(sample);
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(key),
      matchesGoldenFile('gold_files/v1_6_line.png'),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }, tags: ['golden']);

  testWidgets('Pie Chart', (tester) async {
    configureTestView();
    const ValueKey key = ValueKey('paint');
    final Widget sample = getSampleForGoldenTest(key, 'chart_pie');
    await tester.pumpWidget(sample);
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(key),
      matchesGoldenFile('gold_files/v1_6_pie.png'),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }, tags: ['golden']);
}
