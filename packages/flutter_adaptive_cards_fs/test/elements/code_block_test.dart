import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

void main() {
  testWidgets('CodeBlock renders text from spec codeSnippet property', (
    WidgetTester tester,
  ) async {
    const card = {
      'type': 'AdaptiveCard',
      'version': '1.5',
      'body': [
        {
          'type': 'CodeBlock',
          'codeSnippet': 'final answer = 42;',
          'language': 'dart',
          'startLineNumber': 1,
        },
      ],
    };

    await tester.pumpWidget(
      getTestWidgetFromMap(map: card, title: 'CodeBlock codeSnippet'),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('final answer = 42;'), findsOneWidget);
  });

  testWidgets('CodeBlock renders text from legacy code property', (
    WidgetTester tester,
  ) async {
    const card = {
      'type': 'AdaptiveCard',
      'version': '1.5',
      'body': [
        {
          'type': 'CodeBlock',
          'code': 'print("hello");',
          'language': 'dart',
          'startLineNumber': 1,
        },
      ],
    };

    await tester.pumpWidget(
      getTestWidgetFromMap(map: card, title: 'CodeBlock code legacy'),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('print("hello");'), findsOneWidget);
  });
}
