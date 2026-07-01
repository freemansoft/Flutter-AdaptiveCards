import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/actions_config.dart';
import 'package:flutter_test/flutter_test.dart';

import 'utils/test_utils.dart';

void main() {
  testWidgets('Golden Sample 1', (tester) async {
    configureTestView();

    const ValueKey key = ValueKey('paint');
    final Widget sample = getSampleForGoldenTest(key, 'example1');

    // await tester.pumpWidget(SizedBox(width:100,height:100,child:
    // Center(child: RepaintBoundary(child: SizedBox(width:500, height:
    // 1200,child: sample), key: key,))));
    await tester.pumpWidget(sample);
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(key),
      matchesGoldenFile(getGoldenPath('sample1-base.png')),
    );

    expect(find.widgetWithText(ElevatedButton, 'Set due date'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Set due date'));
    await tester.pump();

    await expectLater(
      find.byKey(key),
      matchesGoldenFile(getGoldenPath('sample1_set_due_date.png')),
    );

    expect(find.widgetWithText(ElevatedButton, 'OK'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Comment'));
    await tester.pump();

    await expectLater(
      find.byKey(key),
      matchesGoldenFile(getGoldenPath('sample1_comment.png')),
    );
  }, tags: ['golden']);

  //
  // This test is a little bogus because the frame looks the same after tapping
  // the buttons
  //
  testWidgets('Golden Sample 2', (tester) async {
    configureTestView();

    const ValueKey key = ValueKey('paint');
    final Widget sample = getSampleForGoldenTest(key, 'example2');

    // await tester.pumpWidget(SizedBox(width:100,height:100,child:
    // Center(child: RepaintBoundary(child: SizedBox(width:500, height:
    // 1200,child: sample), key: key,))));
    await tester.pumpWidget(sample);
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(key),
      matchesGoldenFile(getGoldenPath('sample2-base.png')),
    );

    expect(find.widgetWithText(ElevatedButton, "I'll be late"), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, "I'll be late"));
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(key),
      matchesGoldenFile(getGoldenPath('sample2_ill_be_late.png')),
    );

    expect(find.widgetWithText(ElevatedButton, 'Snooze'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Snooze'));
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(key),
      matchesGoldenFile(getGoldenPath('sample2_snooze.png')),
    );
  }, tags: ['golden']);

  testWidgets('Golden Sample 2 Vertical', (tester) async {
    configureTestView();

    const ValueKey key = ValueKey('paint');

    // Load actions config with vertical orientation
    final actionsFile = File('test/hostconfig/actions_config_vertical.json');
    final Map<String, dynamic> actionsJson =
        json.decode(actionsFile.readAsStringSync()) as Map<String, dynamic>;
    final actionsConfig = ActionsConfig.fromJson(actionsJson);
    final hostConfig = HostConfig(actions: actionsConfig);
    final hostConfigs = HostConfigs(light: hostConfig, dark: hostConfig);

    final Widget sample = getTestWidgetFromPath(
      path: 'example2.json',
      key: key,
      hostConfigs: hostConfigs,
    );

    await tester.pumpWidget(sample);
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(key),
      matchesGoldenFile(getGoldenPath('sample2_vertical-base.png')),
    );

    expect(find.widgetWithText(ElevatedButton, "I'll be late"), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, "I'll be late"));
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(key),
      matchesGoldenFile(getGoldenPath('sample2_vertical_ill_be_late.png')),
    );

    expect(find.widgetWithText(ElevatedButton, 'Snooze'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Snooze'));
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(key),
      matchesGoldenFile(getGoldenPath('sample2_vertical_snooze.png')),
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
      matchesGoldenFile(getGoldenPath('sample3-base.png')),
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
      matchesGoldenFile(getGoldenPath('sample4-base.png')),
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
      matchesGoldenFile(getGoldenPath('sample5-base.png')),
    );

    expect(find.widgetWithText(ElevatedButton, 'Steak'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Chicken'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Tofu'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Steak'));
    await tester.pump();

    await expectLater(
      find.byKey(key),
      matchesGoldenFile(getGoldenPath('sample5-steak.png')),
    );

    await tester.tap(find.widgetWithText(ElevatedButton, 'Chicken'));
    await tester.pump();

    await expectLater(
      find.byKey(key),
      matchesGoldenFile(getGoldenPath('sample5-chicken.png')),
    );

    await tester.tap(find.widgetWithText(ElevatedButton, 'Tofu'));
    await tester.pump();

    await expectLater(
      find.byKey(key),
      matchesGoldenFile(getGoldenPath('sample5-tofu.png')),
    );
  }, tags: ['golden']);

  testWidgets('Golden Sample 14', (tester) async {
    configureTestView();

    const ValueKey key = ValueKey('paint');
    final Widget sample = getSampleForGoldenTest(key, 'example14');

    await tester.pumpWidget(sample);
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(key),
      matchesGoldenFile(getGoldenPath('sample14-base.png')),
    );

    await tester.pump(const Duration(seconds: 1));
  }, tags: ['golden']);

  testWidgets('Golden Table 1', (tester) async {
    configureTestView();

    const ValueKey key = ValueKey('paint');
    final Widget sample = getSampleForGoldenTest(key, 'table1');

    await tester.pumpWidget(sample);
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(key),
      matchesGoldenFile(getGoldenPath('table1-base.png')),
    );

    await tester.pump(const Duration(seconds: 1));
  }, tags: ['golden']);

  testWidgets('Golden Sample Table 2', (tester) async {
    configureTestView();

    const ValueKey key = ValueKey('paint');
    final Widget sample = getSampleForGoldenTest(key, 'table2');

    await tester.pumpWidget(sample);
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(key),
      matchesGoldenFile(getGoldenPath('table2-base.png')),
    );

    await tester.pump(const Duration(seconds: 1));
  }, tags: ['golden']);

  testWidgets('Golden Table 3 widths', (tester) async {
    configureTestView();

    const ValueKey key = ValueKey('paint');
    final Widget sample = getSampleForGoldenTest(key, 'table3_widths');

    await tester.pumpWidget(sample);
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(key),
      matchesGoldenFile(getGoldenPath('table3_widths-base.png')),
    );
  }, tags: ['golden']);
}
