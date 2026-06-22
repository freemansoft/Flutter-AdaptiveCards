import 'package:flutter_adaptive_cards_fs/src/cards/containers/table.dart';
import 'package:flutter_adaptive_cards_fs/src/riverpod/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

Map<String, dynamic> _tableCard({bool? isVisible}) => {
  'type': 'AdaptiveCard',
  'version': '1.6',
  'body': [
    {
      'type': 'Table',
      'id': 'tbl1',
      'isVisible': ?isVisible,
      'columns': [
        {'width': 1},
        {'width': 1},
      ],
      'rows': [
        {
          'type': 'TableRow',
          'cells': [
            {
              'type': 'TableCell',
              'items': [
                {'type': 'TextBlock', 'text': 'Cell A'},
              ],
            },
            {
              'type': 'TableCell',
              'items': [
                {'type': 'TextBlock', 'text': 'Cell B'},
              ],
            },
          ],
        },
      ],
    },
  ],
};

void main() {
  testWidgets('isVisible: false in JSON hides Table content', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      getTestWidgetFromMap(
        map: _tableCard(isVisible: false),
        title: 'table visibility static',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Cell A'), findsNothing);
    expect(find.text('Cell B'), findsNothing);
  });

  testWidgets('setVisibility toggles Table content', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      getTestWidgetFromMap(
        map: _tableCard(),
        title: 'table visibility overlay',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Cell A'), findsOneWidget);

    final notifier = ProviderScope.containerOf(
      tester.element(
        find.byWidgetPredicate((w) => w is AdaptiveTable && w.id == 'tbl1'),
      ),
    ).read(adaptiveCardDocumentProvider.notifier);

    Future<void> setVis({required bool visible}) async {
      notifier.setVisibility('tbl1', visible: visible);
      await tester.pump();
    }

    await setVis(visible: false);
    expect(find.text('Cell A'), findsNothing);

    await setVis(visible: true);
    expect(find.text('Cell A'), findsOneWidget);
  });
}
