import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'utils/test_utils.dart';

// Helper to load widget from a subdirectory of samples
// Not needed here
Widget getSampleForGoldenTest(Key key, String sampleName) {
  return getWidget(path: '$sampleName.json', key: key);
}

void configureTestView() {
  RendererBinding.instance.renderViews.first.configuration =
      TestViewConfiguration.fromView(
        size: const Size(500, 700),
        view: PlatformDispatcher.instance.implicitView!,
      );
}

void main() {
  testWidgets('Golden Sample 1', (tester) async {
    configureTestView();

    const ValueKey key = ValueKey('paint');
    final Widget sample = getSampleForGoldenTest(key, 'example1');

    //await tester.pumpWidget(SizedBox(width:100,height:100,child: Center(child: RepaintBoundary(child: SizedBox(width:500, height: 1200,child: sample), key: key,))));
    await tester.pumpWidget(sample);
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(key),
      matchesGoldenFile('gold_files/sample1-base.png'),
    );

    expect(find.widgetWithText(ElevatedButton, 'Set due date'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Set due date'));
    await tester.pump();

    await expectLater(
      find.byKey(key),
      matchesGoldenFile('gold_files/sample1_set_due_date.png'),
    );

    expect(find.widgetWithText(ElevatedButton, 'OK'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Comment'));
    await tester.pump();

    await expectLater(
      find.byKey(key),
      matchesGoldenFile('gold_files/sample1_comment.png'),
    );
  }, tags: ['golden']);

  //
  // TODO(username): This test is a little bogus because the frame looks the same after tapping the buttons
  //
  testWidgets('Golden Sample 2', (tester) async {
    configureTestView();

    const ValueKey key = ValueKey('paint');
    final Widget sample = getSampleForGoldenTest(key, 'example2');

    //await tester.pumpWidget(SizedBox(width:100,height:100,child: Center(child: RepaintBoundary(child: SizedBox(width:500, height: 1200,child: sample), key: key,))));
    await tester.pumpWidget(sample);
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(key),
      matchesGoldenFile('gold_files/sample2-base.png'),
    );

    expect(find.widgetWithText(ElevatedButton, "I'll be late"), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, "I'll be late"));
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(key),
      matchesGoldenFile('gold_files/sample2_ill_be_late.png'),
    );

    expect(find.widgetWithText(ElevatedButton, 'Snooze'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Snooze'));
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(key),
      matchesGoldenFile('gold_files/sample2_snooze.png'),
    );
  }, tags: ['golden']);

  testWidgets('Golden Sample 3', (tester) async {
    configureTestView();

    const ValueKey key = ValueKey('paint');
    final Widget sample = getSampleForGoldenTest(key, 'example3');

    await tester.pumpWidget(sample);
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(key),
      matchesGoldenFile('gold_files/sample3-base.png'),
    );
    await tester.pump(const Duration(seconds: 1));
  }, tags: ['golden']);

  testWidgets('Golden Sample 4', (tester) async {
    configureTestView();

    const ValueKey key = ValueKey('paint');
    final Widget sample = getSampleForGoldenTest(key, 'example4');

    await tester.pumpWidget(sample);
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(key),
      matchesGoldenFile('gold_files/sample4-base.png'),
    );
  }, tags: ['golden']);

  testWidgets('Golden Sample 5', (tester) async {
    configureTestView();

    const ValueKey key = ValueKey('paint');
    final Widget sample = getSampleForGoldenTest(key, 'example5');

    await tester.pumpWidget(sample);
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(key),
      matchesGoldenFile('gold_files/sample5-base.png'),
    );

    expect(find.widgetWithText(ElevatedButton, 'Steak'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Chicken'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Tofu'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Steak'));
    await tester.pump();

    await expectLater(
      find.byKey(key),
      matchesGoldenFile('gold_files/sample5-steak.png'),
    );

    await tester.tap(find.widgetWithText(ElevatedButton, 'Chicken'));
    await tester.pump();

    await expectLater(
      find.byKey(key),
      matchesGoldenFile('gold_files/sample5-chicken.png'),
    );

    await tester.tap(find.widgetWithText(ElevatedButton, 'Tofu'));
    await tester.pump();

    await expectLater(
      find.byKey(key),
      matchesGoldenFile('gold_files/sample5-tofu.png'),
    );
  }, tags: ['golden']);
  // TODO(username): add other tests
  testWidgets('Golden Sample 14', (tester) async {
    configureTestView();

    const ValueKey key = ValueKey('paint');
    final Widget sample = getSampleForGoldenTest(key, 'example14');

    await tester.pumpWidget(sample);
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(key),
      matchesGoldenFile('gold_files/sample14-base.png'),
    );

    await tester.pump(const Duration(seconds: 1));
  }, tags: ['golden']);

  testWidgets('Golden Sample 16', (tester) async {
    configureTestView();

    const ValueKey key = ValueKey('paint');
    final Widget sample = getSampleForGoldenTest(key, 'example16');

    await tester.pumpWidget(sample);
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(key),
      matchesGoldenFile('gold_files/sample16-base.png'),
    );

    await tester.pump(const Duration(seconds: 1));
  }, tags: ['golden']);
}
