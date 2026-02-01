import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/flutter_adaptive_cards.dart';
import 'package:flutter_adaptive_cards/src/cards/adaptive_card_element.dart';
import 'package:flutter_adaptive_cards/src/flutter_raw_adaptive_card.dart';
import 'package:flutter_adaptive_cards/src/inputs/text.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

void main() {
  testWidgets('TextInput renders with label and correct key', (
    WidgetTester tester,
  ) async {
    final Map<String, dynamic> map = {
      'type': 'AdaptiveCard',
      'body': [
        {
          'type': 'Input.Text',
          'id': 'myText',
          'label': 'Full name',
          'placeholder': 'Enter your name',
        },
      ],
    };

    final Widget widget = MaterialApp(
      home: Scaffold(
        body: RawAdaptiveCard.fromMap(
          map: map,
          hostConfig: HostConfig(),
        ),
      ),
    );

    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    expect(find.text('Full name'), findsOneWidget);
    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.byKey(const ValueKey('myText')), findsOneWidget);
  });

  testWidgets('TextInput required validation shows error message', (
    WidgetTester tester,
  ) async {
    final Map<String, dynamic> map = {
      'type': 'AdaptiveCard',
      'body': [
        {
          'type': 'Input.Text',
          'id': 'requiredText',
          'label': 'Required',
          'isRequired': true,
          'errorMessage': 'This field is required',
        },
      ],
    };

    final Widget widget = MaterialApp(
      home: Scaffold(
        body: RawAdaptiveCard.fromMap(
          map: map,
          hostConfig: HostConfig(),
        ),
      ),
    );

    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    final AdaptiveCardElementState cardState = tester.state(
      find.byType(AdaptiveCardElement),
    );

    final bool valid = cardState.formKey.currentState!.validate();

    expect(valid, isFalse);

    // Error message should be visible
    await tester.pump();
    expect(find.text('This field is required'), findsOneWidget);
  });

  testWidgets('TextInput loads initial value from initData and appendInput', (
    WidgetTester tester,
  ) async {
    final Map<String, dynamic> map = {
      'type': 'AdaptiveCard',
      'body': [
        {
          'type': 'Input.Text',
          'id': 'initText',
          'label': 'Init',
        },
      ],
    };

    final Widget widget = MaterialApp(
      home: Scaffold(
        body: RawAdaptiveCard.fromMap(
          map: map,
          initData: const {'initText': 'initial value'},
          hostConfig: HostConfig(),
        ),
      ),
    );

    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    final TextFormField field = tester.widget(
      find.byKey(const ValueKey('initText')),
    );

    expect(field.controller!.text, equals('initial value'));

    // Change text via UI and assert appendInput returns the value
    await tester.enterText(find.byKey(const ValueKey('initText')), 'hello');
    await tester.pump();

    final dynamic state = tester.state(find.byType(AdaptiveTextInput));
    final Map<String, dynamic> out = {};
    state.appendInput(out);
    expect(out['initText'], 'hello');
  });
}
