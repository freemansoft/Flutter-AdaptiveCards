import 'package:flutter_adaptive_cards_fs/src/flutter_raw_adaptive_card.dart';
import 'package:flutter_adaptive_cards_fs/src/riverpod/providers.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

void main() {
  testWidgets(
    'Submit skips overlay-required empty field without calling host',
    (
      WidgetTester tester,
    ) async {
      var submitCount = 0;
      final map = <String, dynamic>{
        'type': 'AdaptiveCard',
        'body': [
          {
            'type': 'Input.Text',
            'id': 'optionalNowRequired',
            'isRequired': false,
          },
        ],
        'actions': [
          {
            'type': 'Action.Submit',
            'id': 'submitAction',
            'title': 'Send',
          },
        ],
      };

      await tester.pumpWidget(
        getTestWidgetFromMap(
          map: map,
          title: 'submit resolved isRequired',
          onSubmit: (_) => submitCount++,
        ),
      );
      await tester.pumpAndSettle();

      final textMap = map['body'][0] as Map<String, dynamic>;
      final container = ProviderScope.containerOf(
        tester.element(find.byKey(generateWidgetKey(textMap))),
      );
      container
          .read(adaptiveCardDocumentProvider.notifier)
          .setIsRequired('optionalNowRequired', required: true);
      await tester.pump();

      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();

      expect(submitCount, 0);

      container
          .read(adaptiveCardDocumentProvider.notifier)
          .setInputValue('optionalNowRequired', 'filled');
      await tester.pump();

      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();

      expect(submitCount, 1);
    },
  );
}
