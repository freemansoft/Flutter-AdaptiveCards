import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/src/inputs/choice_filter.dart';
import 'package:flutter_adaptive_cards/src/inputs/choice_set.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

void main() {
  setUp(() {
    HttpOverrides.global = MyTestHttpOverrides();
  });

  testWidgets('ChoiceFilter filters results based on search text', (
    WidgetTester tester,
  ) async {
    final data = [
      SearchModel(id: '1', name: 'Alice'),
      SearchModel(id: '2', name: 'Bob'),
      SearchModel(id: '3', name: 'Carol'),
    ];

    final Widget widget = MaterialApp(
      home: Scaffold(
        body: ChoiceFilter(
          key: const ValueKey('myFilter'),
          data: data,
          callback: (_) {},
        ),
      ),
    );

    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    // Initially all entries are visible
    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Bob'), findsOneWidget);
    expect(find.text('Carol'), findsOneWidget);

    // Enter search 'al' which should match Alice only
    await tester.enterText(find.byKey(const ValueKey('myFilter')), 'al');
    await tester.pumpAndSettle();

    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Bob'), findsNothing);
    expect(find.text('Carol'), findsNothing);
  });
}
