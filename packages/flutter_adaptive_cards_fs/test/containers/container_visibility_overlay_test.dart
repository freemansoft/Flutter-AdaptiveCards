import 'package:flutter_adaptive_cards_fs/src/cards/containers/container.dart';
import 'package:flutter_adaptive_cards_fs/src/riverpod/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

void main() {
  testWidgets('isVisible: false in JSON hides Container content', (
    WidgetTester tester,
  ) async {
    final map = {
      'type': 'AdaptiveCard',
      'version': '1.6',
      'body': [
        {
          'type': 'Container',
          'id': 'c1',
          'isVisible': false,
          'items': [
            {'type': 'TextBlock', 'text': 'Container content'},
          ],
        },
      ],
    };

    await tester.pumpWidget(
      getTestWidgetFromMap(map: map, title: 'container visibility static'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Container content'), findsNothing);
  });

  testWidgets('setVisibility toggles Container content', (
    WidgetTester tester,
  ) async {
    final map = {
      'type': 'AdaptiveCard',
      'version': '1.6',
      'body': [
        {
          'type': 'Container',
          'id': 'c1',
          'items': [
            {'type': 'TextBlock', 'text': 'Container content'},
          ],
        },
      ],
    };

    await tester.pumpWidget(
      getTestWidgetFromMap(map: map, title: 'container visibility overlay'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Container content'), findsOneWidget);

    final notifier = ProviderScope.containerOf(
      tester.element(
        find.byWidgetPredicate((w) => w is AdaptiveContainer && w.id == 'c1'),
      ),
    ).read(adaptiveCardDocumentProvider.notifier);

    Future<void> setVis({required bool visible}) async {
      notifier.setVisibility('c1', visible: visible);
      await tester.pump();
    }

    await setVis(visible: false);
    expect(find.text('Container content'), findsNothing);

    await setVis(visible: true);
    expect(find.text('Container content'), findsOneWidget);
  });
}
