import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

void main() {
  testWidgets('Input.Rating submits double value', (tester) async {
    SubmitActionInvoke? captured;

    const card = {
      'type': 'AdaptiveCard',
      'version': '1.6',
      'body': [
        {
          'type': 'Input.Rating',
          'id': 'rating',
          'max': 5,
        },
      ],
      'actions': [
        {
          'type': 'Action.Submit',
          'title': 'Submit',
        },
      ],
    };

    await tester.pumpWidget(
      getTestWidgetFromMap(
        map: card,
        title: 'rating submit test',
        onOpenUrl: (_) {},
        onSubmit: (invoke) => captured = invoke,
        onExecute: (_) {},
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.star_border).at(3));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    expect(captured, isNotNull);
    expect(captured!.data['rating'], 4);
  });
}
