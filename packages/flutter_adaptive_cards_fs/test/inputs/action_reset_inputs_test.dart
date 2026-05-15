import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/cards/inputs/choice_set.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

void main() {
  // TODO(username): add missing tests - date, time
  testWidgets('ResetInputs action resets all fields to original values', (
    WidgetTester tester,
  ) async {
    final Widget widget = getTestWidgetFromPath(
      path: 'action_reset_inputs.json',
    );

    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    // Verify initial values in UI
    final choiceState = tester.state<AdaptiveChoiceSetState>(
      find.byType(AdaptiveChoiceSet),
    );
    final Map<String, dynamic> initialChoiceOut = {};
    choiceState.appendInput(initialChoiceOut);
    expect(initialChoiceOut['myChoiceSet'], equals(''));

    expect(
      tester
          .widget<TextFormField>(find.byKey(generateWidgetKeyFromId('myText1')))
          .controller!
          .text,
      equals(''),
    );
    expect(
      tester
          .widget<TextFormField>(find.byKey(generateWidgetKeyFromId('myText2')))
          .controller!
          .text,
      equals('Initial Text'),
    );

    // Change Text values interactively
    await tester.enterText(
      find.byKey(generateWidgetKeyFromId('myText1')),
      'Changed Text 1',
    );
    await tester.enterText(
      find.byKey(generateWidgetKeyFromId('myText2')),
      'Changed Text 2',
    );
    await tester.pump();

    // Change ChoiceSet interactively
    await tester.tap(find.text('Choice 2'));
    await tester.pumpAndSettle();

    // Verify values changed
    expect(
      tester
          .widget<TextFormField>(find.byKey(generateWidgetKeyFromId('myText1')))
          .controller!
          .text,
      equals('Changed Text 1'),
    );
    expect(
      tester
          .widget<TextFormField>(find.byKey(generateWidgetKeyFromId('myText2')))
          .controller!
          .text,
      equals('Changed Text 2'),
    );

    final Map<String, dynamic> choiceOut = {};
    choiceState.appendInput(choiceOut);
    expect(choiceOut['myChoiceSet'], equals('2'));

    // Trigger Action.ResetInputs
    await tester.tap(find.text('Reset Inputs'));
    await tester.pump();

    // Verify all fields returned to their original values
    expect(
      tester
          .widget<TextFormField>(find.byKey(generateWidgetKeyFromId('myText1')))
          .controller!
          .text,
      equals(''),
    );
    expect(
      tester
          .widget<TextFormField>(find.byKey(generateWidgetKeyFromId('myText2')))
          .controller!
          .text,
      equals('Initial Text'),
    );

    final Map<String, dynamic> resetChoiceOut = {};
    choiceState.appendInput(resetChoiceOut);
    expect(resetChoiceOut['myChoiceSet'], equals(''));
  });
}
