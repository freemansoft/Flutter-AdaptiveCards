import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'utils/test_utils.dart';

// Helper to load widget from our v1.6 samples
Widget getSampleForGoldenTest(Key key, String sampleName) {
  // getWidget expects path relative to test/samples/
  final Widget sample = getWidget('v1.6/$sampleName.json');

  return MaterialApp(
    home: RepaintBoundary(
      key: key,
      child: Scaffold(
        appBar: AppBar(title: Text(sampleName)),
        body: Center(child: sample),
      ),
    ),
  );
}

void configureTestView() {
  RendererBinding.instance.renderViews.first.configuration =
      TestViewConfiguration.fromView(
        size: const Size(500, 700),
        view: PlatformDispatcher.instance.implicitView!,
      );
}

void main() {
  setUp(() async {
    HttpOverrides.global = MyTestHttpOverrides();

    // Load fonts (copied from sample_golden_test.dart)
    final fontData = File('assets/fonts/Roboto/Roboto-Regular.ttf')
        .readAsBytes()
        .then((bytes) => ByteData.view(Uint8List.fromList(bytes).buffer));
    final fontLoader = FontLoader('Roboto')..addFont(fontData);
    // Add other weights if needed, sticking to Regular for now or minimal set
    await fontLoader.load();
  });

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
  });

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
  });

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
  });

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
  });

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
  });

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
  });

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
  });
}
