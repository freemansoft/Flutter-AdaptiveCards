import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'utils/test_utils.dart';

Widget getSampleForGoldenTest(Key key, String sampleName) {
  Widget sample = getWidget(sampleName);

  return MaterialApp(
    home: RepaintBoundary(
      key: key,
      child: Scaffold(appBar: AppBar(), body: Center(child: sample)),
    ),
  );
}

void main() {
  // Deliver actual images
  setUp(() async {
    HttpOverrides.global = MyTestHttpOverrides();
    WidgetsBinding
        .instance
        .renderView
        .configuration = TestViewConfiguration.fromView(
      size: const Size(500, 700),
      view: PlatformDispatcher.instance.implicitView!,
    );

    // TODO: Delete this commented out code! Or, use https://pub.dev/packages/golden_toolkit
    final fontData = File('assets/fonts/Roboto/Roboto-Regular.ttf')
        .readAsBytes()
        .then((bytes) => ByteData.view(Uint8List.fromList(bytes).buffer));
    final fontData2 = File('assets/fonts/Roboto/Roboto-Bold.ttf')
        .readAsBytes()
        .then((bytes) => ByteData.view(Uint8List.fromList(bytes).buffer));
    final fontData3 = File('assets/fonts/Roboto/Roboto-Light.ttf')
        .readAsBytes()
        .then((bytes) => ByteData.view(Uint8List.fromList(bytes).buffer));
    final fontData4 = File('assets/fonts/Roboto/Roboto-Medium.ttf')
        .readAsBytes()
        .then((bytes) => ByteData.view(Uint8List.fromList(bytes).buffer));
    final fontData5 = File('assets/fonts/Roboto/Roboto-Thin.ttf')
        .readAsBytes()
        .then((bytes) => ByteData.view(Uint8List.fromList(bytes).buffer));
    final fontLoader =
        FontLoader('Roboto')
          ..addFont(fontData)
          ..addFont(fontData2)
          ..addFont(fontData3)
          ..addFont(fontData4)
          ..addFont(fontData5);
    await fontLoader.load();
  });

  testWidgets('Golden Sample 1', (tester) async {
    ValueKey key = const ValueKey('paint');
    Widget sample = getSampleForGoldenTest(key, 'example1');

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
  });

  ///
  /// TODO: This test is a little bogus because the frame looks the same after tapping the buttons
  ///
  testWidgets('Golden Sample 2', (tester) async {
    ValueKey key = const ValueKey('paint');
    Widget sample = getSampleForGoldenTest(key, 'example2');

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
  });

  testWidgets('Golden Sample 3', (tester) async {
    ValueKey key = const ValueKey('paint');
    Widget sample = getSampleForGoldenTest(key, 'example3');

    await tester.pumpWidget(sample);
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(key),
      matchesGoldenFile('gold_files/sample3-base.png'),
    );
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('Golden Sample 4', (tester) async {
    ValueKey key = const ValueKey('paint');
    Widget sample = getSampleForGoldenTest(key, 'example4');

    await tester.pumpWidget(sample);
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(key),
      matchesGoldenFile('gold_files/sample4-base.png'),
    );
  });

  testWidgets('Golden Sample 5', (tester) async {
    ValueKey key = const ValueKey('paint');
    Widget sample = getSampleForGoldenTest(key, 'example5');

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
  });
  // TODO add other tests
  testWidgets('Golden Sample 14', (tester) async {
    ValueKey key = const ValueKey('paint');
    Widget sample = getSampleForGoldenTest(key, 'example14');

    await tester.pumpWidget(sample);
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(key),
      matchesGoldenFile('gold_files/sample14-base.png'),
    );

    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('Golden Sample 16', (tester) async {
    ValueKey key = const ValueKey('paint');
    Widget sample = getSampleForGoldenTest(key, 'example16');

    await tester.pumpWidget(sample);
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(key),
      matchesGoldenFile('gold_files/sample16-base.png'),
    );

    await tester.pump(const Duration(seconds: 1));
  });
}
