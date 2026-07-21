import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

Map<String, dynamic> factSetCard() {
  return {
    'type': 'AdaptiveCard',
    'version': '1.5',
    'body': [
      {
        'type': 'FactSet',
        'id': 'demoFactSet',
        'facts': [
          {'title': 'Fact 1', 'value': 'Value 1'},
        ],
      },
    ],
  };
}

void main() {
  testWidgets(
    'FactSet title is bold by default when HostConfig omits factSet',
    (tester) async {
      // The default test HostConfig has no `factSet` section, so this exercises
      // the common host case where getFactSetConfig() returns null. The spec
      // default for factSet.title.weight is "Bolder", so the title must still
      // render bold rather than falling back to the normal value weight.
      await tester.pumpWidget(
        getTestWidgetFromMap(
          map: factSetCard(),
          title: 'FactSet title weight test',
        ),
      );
      await tester.pumpAndSettle();

      final Text titleText = tester.widget<Text>(find.text('Fact 1'));
      expect(titleText.style?.fontWeight, FontWeight.w700);
    },
  );
}
