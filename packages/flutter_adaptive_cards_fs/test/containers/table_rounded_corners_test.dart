import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/cards/containers/table.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/host_config.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';
import 'package:flutter_test/flutter_test.dart';
import '../utils/test_utils.dart';

/// Regression tests for the Microsoft Teams `roundedCorners` extension on
/// `Table`. See
/// https://learn.microsoft.com/en-us/microsoftteams/platform/task-modules-and-cards/cards/cards-format
/// and `AdaptiveTableState.build` in `lib/src/cards/containers/table.dart`.
///
/// Unlike Container/ColumnSet/Column (a single `Container` +
/// `getDecorationFromMap`), `Table` renders via a bespoke Flutter [Table], so
/// rounding is wired as a [ClipRRect] wrapper (clips cell fills + corners)
/// plus a [TableBorder.borderRadius] on the grid border — not a
/// `BoxDecoration.borderRadius`. The corner radius is resolved via
/// `ReferenceResolver.resolveCornerRadius()` (HostConfig `cornerRadius`,
/// default 8 — see `FallbackConfigs.cornerRadius`).
void main() {
  Map<String, dynamic> buildTableMap({
    required bool? roundedCorners,
    required bool showGridLines,
  }) => {
    'type': 'Table',
    'id': 'testTable',
    'showGridLines': showGridLines,
    'roundedCorners': ?roundedCorners,
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
              {'type': 'TextBlock', 'text': 'A'},
            ],
          },
          {
            'type': 'TableCell',
            'items': [
              {'type': 'TextBlock', 'text': 'B'},
            ],
          },
        ],
      },
      {
        'type': 'TableRow',
        'cells': [
          {
            'type': 'TableCell',
            'items': [
              {'type': 'TextBlock', 'text': 'C'},
            ],
          },
          {
            'type': 'TableCell',
            'items': [
              {'type': 'TextBlock', 'text': 'D'},
            ],
          },
        ],
      },
    ],
  };

  /// The `ClipRRect` this code wraps around the `Table` when rounded, found
  /// as a descendant of the table's adaptive wrapper key (so it doesn't match
  /// unrelated `ClipRRect`s elsewhere in the tree).
  Finder findClipRRect(Map<String, dynamic> tableMap) {
    final key = generateAdaptiveWidgetKey(tableMap);
    return find.descendant(
      of: find.byKey(key),
      matching: find.byType(ClipRRect),
    );
  }

  Table findTable(WidgetTester tester, String tableKey) {
    return tester.widget<Table>(
      find.byKey(AdaptiveTable.tableColumnKey(tableKey)),
    );
  }

  testWidgets(
    'roundedCorners:true + showGridLines:true clips the table and rounds '
    'the grid border',
    (WidgetTester tester) async {
      final tableMap = buildTableMap(
        roundedCorners: true,
        showGridLines: true,
      );
      final cardMap = {
        'type': 'AdaptiveCard',
        'version': '1.5',
        'body': [tableMap],
      };

      await tester.pumpWidget(
        getTestWidgetFromMap(
          map: cardMap,
          title: 'Table roundedCorners + gridlines test',
        ),
      );
      await tester.pumpAndSettle();

      expect(findClipRRect(tableMap), findsOneWidget);
      final clipRRect = tester.widget<ClipRRect>(findClipRRect(tableMap));
      expect(clipRRect.borderRadius, equals(BorderRadius.circular(8)));

      final table = findTable(tester, 'testTable_adaptive');
      final border = table.border!;
      expect(border.borderRadius, equals(BorderRadius.circular(8)));
    },
  );

  testWidgets(
    'roundedCorners:true + showGridLines:false still clips the table '
    '(no border to round)',
    (WidgetTester tester) async {
      final tableMap = buildTableMap(
        roundedCorners: true,
        showGridLines: false,
      );
      final cardMap = {
        'type': 'AdaptiveCard',
        'version': '1.5',
        'body': [tableMap],
      };

      await tester.pumpWidget(
        getTestWidgetFromMap(
          map: cardMap,
          title: 'Table roundedCorners no gridlines test',
        ),
      );
      await tester.pumpAndSettle();

      expect(findClipRRect(tableMap), findsOneWidget);
      final clipRRect = tester.widget<ClipRRect>(findClipRRect(tableMap));
      expect(clipRRect.borderRadius, equals(BorderRadius.circular(8)));

      final table = findTable(tester, 'testTable_adaptive');
      expect(table.border, isNull);
    },
  );

  testWidgets(
    'without roundedCorners the table stays square: no ClipRRect added, '
    'and a shown grid border has a zero borderRadius',
    (WidgetTester tester) async {
      final tableMap = buildTableMap(
        roundedCorners: null,
        showGridLines: true,
      );
      final cardMap = {
        'type': 'AdaptiveCard',
        'version': '1.5',
        'body': [tableMap],
      };

      await tester.pumpWidget(
        getTestWidgetFromMap(
          map: cardMap,
          title: 'Table square (default) test',
        ),
      );
      await tester.pumpAndSettle();

      expect(findClipRRect(tableMap), findsNothing);

      final table = findTable(tester, 'testTable_adaptive');
      final border = table.border!;
      expect(border.borderRadius, equals(BorderRadius.zero));
    },
  );

  testWidgets(
    'roundedCorners:true resolves the radius from HostConfig `cornerRadius` '
    'rather than a fixed value',
    (WidgetTester tester) async {
      final tableMap = buildTableMap(
        roundedCorners: true,
        showGridLines: true,
      );
      final cardMap = {
        'type': 'AdaptiveCard',
        'version': '1.5',
        'body': [tableMap],
      };

      await tester.pumpWidget(
        getTestWidgetFromMap(
          map: cardMap,
          title: 'Table roundedCorners custom HostConfig test',
          hostConfigs: HostConfigs(
            light: HostConfig.fromJson(<String, dynamic>{'cornerRadius': 20}),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final clipRRect = tester.widget<ClipRRect>(findClipRRect(tableMap));
      expect(clipRRect.borderRadius, equals(BorderRadius.circular(20)));

      final table = findTable(tester, 'testTable_adaptive');
      final border = table.border!;
      expect(border.borderRadius, equals(BorderRadius.circular(20)));
    },
  );
}
