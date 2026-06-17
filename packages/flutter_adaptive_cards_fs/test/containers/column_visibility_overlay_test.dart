import 'package:flutter_adaptive_cards_fs/src/cards/containers/column.dart';
import 'package:flutter_adaptive_cards_fs/src/cards/containers/column_set.dart';
import 'package:flutter_adaptive_cards_fs/src/riverpod/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

void main() {
  group('AdaptiveColumn visibility overlay', () {
    testWidgets('isVisible: false in JSON hides Column content', (
      WidgetTester tester,
    ) async {
      final map = {
        'type': 'AdaptiveCard',
        'version': '1.6',
        'body': [
          {
            'type': 'ColumnSet',
            'columns': [
              {
                'type': 'Column',
                'id': 'col1',
                'isVisible': false,
                'items': [
                  {'type': 'TextBlock', 'text': 'Column content'},
                ],
              },
            ],
          },
        ],
      };

      await tester.pumpWidget(
        getTestWidgetFromMap(map: map, title: 'column visibility static'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Column content'), findsNothing);
    });

    testWidgets('setVisibility toggles Column content', (
      WidgetTester tester,
    ) async {
      final map = {
        'type': 'AdaptiveCard',
        'version': '1.6',
        'body': [
          {
            'type': 'ColumnSet',
            'columns': [
              {
                'type': 'Column',
                'id': 'col1',
                'items': [
                  {'type': 'TextBlock', 'text': 'Column content'},
                ],
              },
            ],
          },
        ],
      };

      await tester.pumpWidget(
        getTestWidgetFromMap(map: map, title: 'column visibility overlay'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Column content'), findsOneWidget);

      final notifier = ProviderScope.containerOf(
        tester.element(
          find.byWidgetPredicate((w) => w is AdaptiveColumn && w.id == 'col1'),
        ),
      ).read(adaptiveCardDocumentProvider.notifier);

      Future<void> setVis({required bool visible}) async {
        notifier.setVisibility('col1', visible: visible);
        await tester.pump();
      }

      await setVis(visible: false);
      expect(find.text('Column content'), findsNothing);

      await setVis(visible: true);
      expect(find.text('Column content'), findsOneWidget);
    });
  });

  group('AdaptiveColumnSet visibility overlay', () {
    testWidgets('isVisible: false in JSON hides ColumnSet content', (
      WidgetTester tester,
    ) async {
      final map = {
        'type': 'AdaptiveCard',
        'version': '1.6',
        'body': [
          {
            'type': 'ColumnSet',
            'id': 'cs1',
            'isVisible': false,
            'columns': [
              {
                'type': 'Column',
                'items': [
                  {'type': 'TextBlock', 'text': 'ColumnSet content'},
                ],
              },
            ],
          },
        ],
      };

      await tester.pumpWidget(
        getTestWidgetFromMap(map: map, title: 'columnset visibility static'),
      );
      await tester.pumpAndSettle();

      expect(find.text('ColumnSet content'), findsNothing);
    });

    testWidgets('setVisibility toggles ColumnSet content', (
      WidgetTester tester,
    ) async {
      final map = {
        'type': 'AdaptiveCard',
        'version': '1.6',
        'body': [
          {
            'type': 'ColumnSet',
            'id': 'cs1',
            'columns': [
              {
                'type': 'Column',
                'items': [
                  {'type': 'TextBlock', 'text': 'ColumnSet content'},
                ],
              },
            ],
          },
        ],
      };

      await tester.pumpWidget(
        getTestWidgetFromMap(map: map, title: 'columnset visibility overlay'),
      );
      await tester.pumpAndSettle();

      expect(find.text('ColumnSet content'), findsOneWidget);

      final notifier = ProviderScope.containerOf(
        tester.element(
          find.byWidgetPredicate(
            (w) => w is AdaptiveColumnSet && w.id == 'cs1',
          ),
        ),
      ).read(adaptiveCardDocumentProvider.notifier);

      Future<void> setVis({required bool visible}) async {
        notifier.setVisibility('cs1', visible: visible);
        await tester.pump();
      }

      await setVis(visible: false);
      expect(find.text('ColumnSet content'), findsNothing);

      await setVis(visible: true);
      expect(find.text('ColumnSet content'), findsOneWidget);
    });
  });
}
