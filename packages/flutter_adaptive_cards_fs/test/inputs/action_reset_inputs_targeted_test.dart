import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

void main() {
  testWidgets('targeted ResetInputs resets only listed fields', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      getTestWidgetFromPath(path: 'action_reset_inputs_targeted.json'),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(generateWidgetKeyFromId('fieldA')),
      'Changed A',
    );
    await tester.enterText(
      find.byKey(generateWidgetKeyFromId('fieldB')),
      'Changed B',
    );
    await tester.enterText(
      find.byKey(generateWidgetKeyFromId('fieldC')),
      'Changed C',
    );
    await tester.enterText(
      find.byKey(generateWidgetKeyFromId('fieldD')),
      'Changed D',
    );
    await tester.pump();

    await tester.tap(find.text('Reset A & B'));
    await tester.pump();

    expect(
      tester
          .widget<TextFormField>(find.byKey(generateWidgetKeyFromId('fieldA')))
          .controller!
          .text,
      equals(''),
    );
    expect(
      tester
          .widget<TextFormField>(find.byKey(generateWidgetKeyFromId('fieldB')))
          .controller!
          .text,
      equals('Baseline B'),
    );
    expect(
      tester
          .widget<TextFormField>(find.byKey(generateWidgetKeyFromId('fieldC')))
          .controller!
          .text,
      equals('Changed C'),
    );
    expect(
      tester
          .widget<TextFormField>(find.byKey(generateWidgetKeyFromId('fieldD')))
          .controller!
          .text,
      equals('Changed D'),
    );

    await tester.enterText(
      find.byKey(generateWidgetKeyFromId('fieldA')),
      'Changed A again',
    );
    await tester.enterText(
      find.byKey(generateWidgetKeyFromId('fieldB')),
      'Changed B again',
    );
    await tester.pump();

    await tester.tap(find.text('Reset C & D'));
    await tester.pump();

    expect(
      tester
          .widget<TextFormField>(find.byKey(generateWidgetKeyFromId('fieldA')))
          .controller!
          .text,
      equals('Changed A again'),
    );
    expect(
      tester
          .widget<TextFormField>(find.byKey(generateWidgetKeyFromId('fieldB')))
          .controller!
          .text,
      equals('Changed B again'),
    );
    expect(
      tester
          .widget<TextFormField>(find.byKey(generateWidgetKeyFromId('fieldC')))
          .controller!
          .text,
      equals('Baseline C'),
    );
    expect(
      tester
          .widget<TextFormField>(find.byKey(generateWidgetKeyFromId('fieldD')))
          .controller!
          .text,
      equals(''),
    );
  });
}
