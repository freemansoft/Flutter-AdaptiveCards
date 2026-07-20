import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/models/action_invoke.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

const Map<String, dynamic> _inlineSubmit = {
  'type': 'Action.Submit',
  'id': 'send',
  'title': 'Send',
};

Map<String, dynamic> _cardWithInlineAction() => {
  'type': 'AdaptiveCard',
  'body': [
    {
      'type': 'Input.Text',
      'id': 'message',
      'placeholder': 'Type a message',
      'inlineAction': _inlineSubmit,
    },
  ],
};

Finder _inlineActionButtonFinder() => find.descendant(
  of: find.byKey(generateAdaptiveWidgetKey(_inlineSubmit)),
  matching: find.byType(ElevatedButton),
);

void main() {
  testWidgets('inlineAction renders beside the field as a sibling', (
    WidgetTester tester,
  ) async {
    final map = _cardWithInlineAction();
    final textMap = map['body'][0] as Map<String, dynamic>;

    await tester.pumpWidget(
      getTestWidgetFromMap(map: map, title: 'inlineAction renders beside'),
    );
    await tester.pumpAndSettle();

    // Field is present and still editable.
    expect(find.byKey(generateWidgetKey(textMap)), findsOneWidget);
    expect(find.byType(TextFormField), findsOneWidget);

    // Inline action button is present, found via its own deterministic key.
    expect(
      find.byKey(generateAdaptiveWidgetKey(_inlineSubmit)),
      findsWidgets,
    );
    expect(_inlineActionButtonFinder(), findsOneWidget);
    expect(find.text('Send'), findsOneWidget);

    // Both live in the same Row, i.e. as siblings beside the field.
    final rowFinder = find.ancestor(
      of: find.byKey(generateAdaptiveWidgetKey(_inlineSubmit)),
      matching: find.byType(Row),
    );
    expect(rowFinder, findsWidgets);

    await tester.enterText(
      find.byKey(generateWidgetKey(textMap)),
      'still editable',
    );
    await tester.pump();
    final field = tester.widget<TextFormField>(
      find.byKey(generateWidgetKey(textMap)),
    );
    expect(field.controller!.text, 'still editable');
  });

  testWidgets(
    'tapping the inline action drives the real submit pipeline with the '
    'typed field value',
    (WidgetTester tester) async {
      SubmitActionInvoke? captured;
      final map = _cardWithInlineAction();
      final textMap = map['body'][0] as Map<String, dynamic>;

      await tester.pumpWidget(
        getTestWidgetFromMap(
          map: map,
          title: 'inlineAction tap drives submit',
          onSubmit: (invoke) => captured = invoke,
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(generateWidgetKey(textMap)),
        'hello from inline action',
      );
      await tester.pump();

      await tester.tap(_inlineActionButtonFinder());
      await tester.pumpAndSettle();

      expect(captured, isNotNull);
      expect(
        captured!.data['message'],
        'hello from inline action',
      );
    },
  );

  testWidgets('no inlineAction leaves the field unchanged (regression)', (
    WidgetTester tester,
  ) async {
    final map = <String, dynamic>{
      'type': 'AdaptiveCard',
      'body': [
        {
          'type': 'Input.Text',
          'id': 'plainMessage',
          'placeholder': 'Type a message',
        },
      ],
    };
    final textMap = map['body'][0] as Map<String, dynamic>;

    await tester.pumpWidget(
      getTestWidgetFromMap(map: map, title: 'no inlineAction'),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(generateWidgetKey(textMap)), findsOneWidget);
    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.byType(ElevatedButton), findsNothing);
  });
}
