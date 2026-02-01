import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_adaptive_cards/src/elements/actions/popover.dart';
import 'package:flutter_test/flutter_test.dart';

import 'utils/test_utils.dart';

// Helper to load widget from our v1.6 samples
Widget getSampleForGoldenTest(Key key, String sampleName) {
  // getWidget expects path relative to test/samples/
  return getWidget(path: 'v1.6/$sampleName.json', key: key);
}

void configureTestView() {
  RendererBinding.instance.renderViews.first.configuration =
      TestViewConfiguration.fromView(
        size: const Size(500, 700),
        view: PlatformDispatcher.instance.implicitView!,
      );
}

void main() {
  testWidgets('Golden Badge', (tester) async {
    configureTestView();
    const ValueKey key = ValueKey('paint');
    final Widget sample = getSampleForGoldenTest(key, 'badge');
    await tester.pumpWidget(sample);
    await tester.pumpAndSettle();

    // We don't have goldens yet, this first run might just pass or fail saying missing golden.
    // We rely on the fact that we can generate them or just verify it renders without error.
    await expectLater(
      find.byKey(key),
      matchesGoldenFile('gold_files/v1_6_badge.png'),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }, tags: ['golden']);

  testWidgets('Golden Rating', (tester) async {
    configureTestView();
    const ValueKey key = ValueKey('paint');
    final Widget sample = getSampleForGoldenTest(key, 'rating');
    await tester.pumpWidget(sample);
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(key),
      matchesGoldenFile('gold_files/v1_6_rating.png'),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }, tags: ['golden']);

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

  testWidgets('Golden Carousel', (tester) async {
    configureTestView();
    const ValueKey key = ValueKey('paint');
    final Widget sample = getSampleForGoldenTest(key, 'carousel');
    await tester.pumpWidget(sample);
    await tester.pumpAndSettle();
    // Carousel has autoplay, pump might need time

    await expectLater(
      find.byKey(key),
      matchesGoldenFile('gold_files/v1_6_carousel.png'),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }, tags: ['golden']);

  testWidgets('Golden Accordion', (tester) async {
    configureTestView();
    const ValueKey key = ValueKey('paint');
    final Widget sample = getSampleForGoldenTest(key, 'accordion');
    await tester.pumpWidget(sample);
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(key),
      matchesGoldenFile('gold_files/v1_6_accordion.png'),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }, tags: ['golden']);

  testWidgets('Golden CodeBlock', (tester) async {
    configureTestView();
    const ValueKey key = ValueKey('paint');
    final Widget sample = getSampleForGoldenTest(key, 'code_block');
    await tester.pumpWidget(sample);
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(key),
      matchesGoldenFile('gold_files/v1_6_code_block.png'),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }, tags: ['golden']);

  testWidgets('Golden ProgressBar', (tester) async {
    configureTestView();
    const ValueKey key = ValueKey('paint');
    final Widget sample = getSampleForGoldenTest(key, 'progress_bar');
    await tester.pumpWidget(sample);
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(key),
      matchesGoldenFile('gold_files/v1_6_progress_bar.png'),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }, tags: ['golden']);

  testWidgets('Golden Popover', (tester) async {
    configureTestView();
    const ValueKey key = ValueKey('paint');
    final Widget sample = getSampleForGoldenTest(key, 'popover');
    await tester.pumpWidget(sample);
    await tester.pumpAndSettle();

    // Tap the button
    await tester.tap(find.text('Show Popover'));
    await tester.pumpAndSettle();

    // Verify text in popover
    expect(find.text('This is a popover!'), findsOneWidget);

    // Capture the whole MaterialApp to include the Dialog overlay

    // appears the they are top to bottom.
    // Not sure whey we have a MaterialApp for the dialog.
    await expectLater(
      find.byType(AdaptivePopoverContainer),
      matchesGoldenFile('gold_files/v1_6_popover_dialog.png'),
    );
    await expectLater(
      find.byType(MaterialApp).last,
      matchesGoldenFile('gold_files/v1_6_popover_base.png'),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }, tags: ['golden']);
}
