import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/cards/inputs/choice_filter.dart';
import 'package:flutter_adaptive_cards_fs/src/models/choice.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ChoiceFilter filters results based on search text', (
    WidgetTester tester,
  ) async {
    final data = [
      const Choice(title: 'Alice', value: '1'),
      const Choice(title: 'Bob', value: '2'),
      const Choice(title: 'Carol', value: '3'),
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
