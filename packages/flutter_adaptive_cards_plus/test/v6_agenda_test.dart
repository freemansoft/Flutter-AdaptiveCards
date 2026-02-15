import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'utils/test_utils.dart';

/// These test just validate the samples render without errors
/// This json failed rendering in the past
///
void main() {
  testWidgets('Agenda-ColSet-1 smoke test', (tester) async {
    final Widget widget = getTestWidgetFromPath(
      path: 'v1.5/Agenda-ColSet-1.json',
    );

    await tester.pumpWidget(widget);
    await tester.pump(
      const Duration(seconds: 1),
    ); // skip past any activity or animation
  });

  testWidgets('Agenda-ColSet-2 smoke test', (tester) async {
    final Widget widget = getTestWidgetFromPath(
      path: 'v1.5/Agenda-ColSet-2.json',
    );

    await tester.pumpWidget(widget);
    await tester.pump(
      const Duration(seconds: 1),
    ); // skip past any activity or animation
  });

  testWidgets('Agenda-ColSet-3 smoke test', (tester) async {
    final Widget widget = getTestWidgetFromPath(
      path: 'v1.5/Agenda-ColSet-3.json',
    );

    await tester.pumpWidget(widget);
    await tester.pump(
      const Duration(seconds: 1),
    ); // skip past any activity or animation
  });

  testWidgets('Agenda-ColSet-4 smoke test', (tester) async {
    final Widget widget = getTestWidgetFromPath(
      path: 'v1.5/Agenda-ColSet-4.json',
    );

    await tester.pumpWidget(widget);
    await tester.pump(
      const Duration(seconds: 1),
    ); // skip past any activity or animation
  });

  testWidgets('Agenda-full smoke test', (tester) async {
    final Widget widget = getTestWidgetFromPath(path: 'v1.5/Agenda-full.json');

    // widget = SingleChildScrollView(child: IntrinsicHeight(child: widget));

    await tester.pumpWidget(widget);
    await tester.pump(
      const Duration(seconds: 1),
    ); // skip past any activity or animation
  }, skip: true);
}
