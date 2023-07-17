import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'utils/test_utils.dart';

void main() {
  // Deliver actual images
  setUp(() {
    HttpOverrides.global = MyTestHttpOverrides();
  });

  testWidgets('Activity Update test', (tester) async {
    Widget widget = getWidthDefaultHostConfig('example1');

    await tester.pumpWidget(widget);

    // TODO: Why don't these finds for text work like the objects do?

    // At the top and at assigned to:
    // expect(find.text('Matt Hidinger'), findsNWidgets(2));

    // expect(
    //     find.text('Now that we have defined the main rules and features of'
    //         ' the format, we need to produce a schema and publish it to GitHub. '
    //         'The schema will be the starting point of our reference documentation.'),
    //     findsOneWidget);

    expect(find.byType(Image), findsOneWidget);

    // The two buttons "Set due date" and "Comment"
    expect(find.byType(ElevatedButton), findsNWidgets(2));

    expect(find.widgetWithText(ElevatedButton, 'Set due date'), findsOneWidget);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Set due date'));
    await tester.pump();

    expect(find.widgetWithText(ElevatedButton, "OK"), findsOneWidget);

    Widget button =
        tester.firstWidget(find.widgetWithText(ElevatedButton, "OK"));

    await tester.tap(find.widgetWithText(ElevatedButton, "Comment"));
    await tester.pump();

    expect(find.byType(ElevatedButton), findsNWidgets(3));

    expect(find.widgetWithText(ElevatedButton, "OK"), findsOneWidget);

    // Also has OK widget but it's a different instance

    expect(find.byWidget(button), findsNothing);

    await tester.pump(
        const Duration(seconds: 1)); // skip past any activity or animation
  });
}
