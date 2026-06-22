import 'package:flutter_adaptive_cards_fs/src/cards/elements/compound_button.dart';
import 'package:flutter_adaptive_cards_fs/src/riverpod/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

void main() {
  testWidgets('isVisible: false in JSON hides CompoundButton', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      getTestWidgetFromMap(
        map: {
          'type': 'AdaptiveCard',
          'version': '1.6',
          'body': [
            {
              'type': 'CompoundButton',
              'id': 'cb1',
              'isVisible': false,
              'title': 'Click Me',
            },
          ],
        },
        title: 'compound button visibility static',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Click Me'), findsNothing);
  });

  testWidgets('setVisibility toggles CompoundButton', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      getTestWidgetFromMap(
        map: {
          'type': 'AdaptiveCard',
          'version': '1.6',
          'body': [
            {
              'type': 'CompoundButton',
              'id': 'cb1',
              'title': 'Click Me',
            },
          ],
        },
        title: 'compound button visibility overlay',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Click Me'), findsOneWidget);

    final notifier = ProviderScope.containerOf(
      tester.element(
        find.byWidgetPredicate(
          (w) => w is AdaptiveCompoundButton && w.id == 'cb1',
        ),
      ),
    ).read(adaptiveCardDocumentProvider.notifier);

    Future<void> setVis({required bool visible}) async {
      notifier.setVisibility('cb1', visible: visible);
      await tester.pump();
    }

    await setVis(visible: false);
    expect(find.text('Click Me'), findsNothing);

    await setVis(visible: true);
    expect(find.text('Click Me'), findsOneWidget);
  });
}
