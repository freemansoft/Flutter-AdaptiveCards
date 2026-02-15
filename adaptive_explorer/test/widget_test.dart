// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:adaptive_explorer/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App starts with empty state and buttons on AppBar', (
    tester,
  ) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const AdaptiveExplorerApp());

    // Verify that our app starts with the selection message.
    expect(find.text('Select a template to view'), findsOneWidget);

    // Validate that the open template and open data buttons are on the AppBar
    final appBar = find.byType(AppBar);
    expect(
      find.descendant(of: appBar, matching: find.text('Open Template')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: appBar, matching: find.text('Open Data')),
      findsOneWidget,
    );

    // Also verify icons for good measure
    expect(find.byIcon(Icons.file_open), findsOneWidget);
    expect(find.byIcon(Icons.data_object), findsOneWidget);
  });
}
