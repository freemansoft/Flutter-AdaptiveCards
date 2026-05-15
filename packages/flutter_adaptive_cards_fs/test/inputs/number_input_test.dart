import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/cards/adaptive_card_element.dart';
import 'package:flutter_adaptive_cards_fs/src/cards/inputs/number.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';
import 'package:flutter_test/flutter_test.dart';
import '../utils/test_utils.dart';

void main() {
  testWidgets('NumberInput renders with correct key', (
    WidgetTester tester,
  ) async {
    final Map<String, dynamic> map = {
      'type': 'AdaptiveCard',
      'body': [
        {
          'type': 'Input.Number',
          'id': 'myNumber',
          'label': 'Age',
          'min': 0,
          'max': 120,
        },
      ],
    };

    final Widget widget = getTestWidgetFromMap(
      map: map,
      title: 'Number Input Test',
    );

    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    final numMap = map['body'][0] as Map<String, dynamic>;
    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.byKey(generateWidgetKey(numMap)), findsOneWidget);
  });

  testWidgets('NumberInput required validation shows error', (
    WidgetTester tester,
  ) async {
    final Map<String, dynamic> map = {
      'type': 'AdaptiveCard',
      'body': [
        {
          'type': 'Input.Number',
          'id': 'requiredNumber',
          'label': 'Required number',
          'isRequired': true,
          'errorMessage': 'Number required',
        },
      ],
    };

    final Widget widget = getTestWidgetFromMap(
      map: map,
      title: 'Number Input Validation Test',
    );

    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    final AdaptiveCardElementState cardState = tester.state(
      find.byType(AdaptiveCardElement),
    );

    final bool valid = cardState.formKey.currentState!.validate();

    expect(valid, isFalse);
    await tester.pump();
    expect(find.text('Number required'), findsOneWidget);
  });

  testWidgets('NumberInput respects min/max and supports init/append', (
    WidgetTester tester,
  ) async {
    final Map<String, dynamic> map = {
      'type': 'AdaptiveCard',
      'body': [
        {
          'type': 'Input.Number',
          'id': 'initNumber',
          'label': 'Init Number',
          'min': 10,
          'max': 20,
        },
      ],
    };

    final Widget widget = getTestWidgetFromMap(
      map: map,
      title: 'Number Input initData Test',
      initData: const {'initNumber': '15'},
    );

    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    final numMap = map['body'][0] as Map<String, dynamic>;
    final TextFormField field = tester.widget(
      find.byKey(generateWidgetKey(numMap)),
    );

    expect(field.controller!.text, equals('15'));

    // Entering a value outside of min/max should be rejected by formatter
    await tester.enterText(find.byKey(generateWidgetKey(numMap)), '5');
    await tester.pump();

    final TextFormField fieldAfter = tester.widget(
      find.byKey(generateWidgetKey(numMap)),
    );

    expect(fieldAfter.controller!.text, isNot(equals('5')));

    // Enter a valid value
    await tester.enterText(find.byKey(generateWidgetKey(numMap)), '12');
    await tester.pump();

    final dynamic state = tester.state(find.byType(AdaptiveNumberInput));
    final Map<String, dynamic> out = {};
    state.appendInput(out);
    expect(out['initNumber'], '12');
  });
}
