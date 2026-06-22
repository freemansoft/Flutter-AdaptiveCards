import 'package:flutter_adaptive_cards_fs/src/cards/elements/tab_set.dart';
import 'package:flutter_adaptive_cards_fs/src/riverpod/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

void main() {
  testWidgets('isVisible: false in JSON hides TabSet', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      getTestWidgetFromMap(
        map: {
          'type': 'AdaptiveCard',
          'version': '1.6',
          'body': [
            {
              'type': 'TabSet',
              'id': 'ts1',
              'isVisible': false,
              'tabs': [
                {
                  'title': 'First Tab',
                  'items': [
                    {'type': 'TextBlock', 'text': 'Tab body'},
                  ],
                },
              ],
            },
          ],
        },
        title: 'tabset visibility static',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('First Tab'), findsNothing);
  });

  testWidgets('setVisibility toggles TabSet', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      getTestWidgetFromMap(
        map: {
          'type': 'AdaptiveCard',
          'version': '1.6',
          'body': [
            {
              'type': 'TabSet',
              'id': 'ts1',
              'tabs': [
                {
                  'title': 'First Tab',
                  'items': [
                    {'type': 'TextBlock', 'text': 'Tab body'},
                  ],
                },
              ],
            },
          ],
        },
        title: 'tabset visibility overlay',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('First Tab'), findsOneWidget);

    final notifier = ProviderScope.containerOf(
      tester.element(
        find.byWidgetPredicate((w) => w is AdaptiveTabSet && w.id == 'ts1'),
      ),
    ).read(adaptiveCardDocumentProvider.notifier);

    Future<void> setVis({required bool visible}) async {
      notifier.setVisibility('ts1', visible: visible);
      await tester.pump();
    }

    await setVis(visible: false);
    expect(find.text('First Tab'), findsNothing);

    await setVis(visible: true);
    expect(find.text('First Tab'), findsOneWidget);
  });
}
