import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/cards/containers/table.dart';
import 'package:flutter_adaptive_cards_fs/src/cards/elements/text_block.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/theme_color_fallbacks.dart';
import 'package:flutter_test/flutter_test.dart';
import '../utils/test_utils.dart';

void main() {
  final themeContainerStyles = ThemeColorFallbacks(ThemeData()).containerStyles;

  group('AdaptiveTable', () {
    testWidgets('renders basic table with default properties', (tester) async {
      final cardMap = {
        'type': 'AdaptiveCard',
        'version': '1.5',
        'body': [
          {
            'type': 'Table',
            'id': 'testTable',
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
                      {'type': 'TextBlock', 'text': 'Cell 1'},
                    ],
                  },
                  {
                    'type': 'TableCell',
                    'items': [
                      {'type': 'TextBlock', 'text': 'Cell 2'},
                    ],
                  },
                ],
              },
            ],
          },
        ],
      };

      await tester.pumpWidget(
        getTestWidgetFromMap(
          map: cardMap,
          title: 'Basic Table Test',
        ),
      );

      await tester.pumpAndSettle();

      const tableKey = 'testTable_adaptive';
      expect(
        find.byKey(AdaptiveTable.tableColumnKey(tableKey)),
        findsOneWidget,
      );
      expect(find.text('Cell 1'), findsOneWidget);
      expect(find.text('Cell 2'), findsOneWidget);
    });

    testWidgets('parses showGridLines=false', (tester) async {
      final cardMap = {
        'type': 'AdaptiveCard',
        'version': '1.5',
        'body': [
          {
            'type': 'Table',
            'id': 'testTable',
            'showGridLines': false,
            'columns': [
              {'width': 1},
            ],
            'rows': [
              {
                'type': 'TableRow',
                'cells': [
                  {
                    'type': 'TableCell',
                    'items': [
                      {'type': 'TextBlock', 'text': 'Cell 1'},
                    ],
                  },
                  {
                    'type': 'TableCell',
                    'items': [
                      {'type': 'TextBlock', 'text': 'Cell 2'},
                    ],
                  },
                ],
              },
            ],
          },
        ],
      };

      await tester.pumpWidget(
        getTestWidgetFromMap(
          map: cardMap,
          title: 'ShowGridLines False Test',
        ),
      );

      await tester.pumpAndSettle();

      // Should not find Dividers when showGridLines is false
      // expect(find.byType(Divider), findsNothing);
      expect(find.byType(VerticalDivider), findsNothing);

      // Should find SizedBox (spacing) instead 1 row separator (between row 1
      // and row end? no, between rows), only 1 row here? Wait, 1 row means no
      // row separators. But 1 column? 1 column means no column separators.
      // Let's add more rows/columns to verify spacing.
    });

    testWidgets('adds spacing when showGridLines=false', (tester) async {
      final cardMap = {
        'type': 'AdaptiveCard',
        'version': '1.5',
        'body': [
          {
            'type': 'Table',
            'id': 'testTable',
            'showGridLines': false,
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
          },
        ],
      };

      await tester.pumpWidget(
        getTestWidgetFromMap(
          map: cardMap,
          title: 'Spacing Test',
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(AdaptiveTable),
          matching: find.byType(Divider),
        ),
        findsNothing,
      );
      expect(find.byType(VerticalDivider), findsNothing);

      const tableKey = 'testTable_adaptive';

      // Flutter Table holds rows directly — no spacer rows when
      // showGridLines=false.
      final columnFinder = find.byKey(AdaptiveTable.tableColumnKey(tableKey));
      final table = tester.widget<Table>(columnFinder);
      expect(
        table.children.length,
        2,
      ); // Row 1, Row 2 — no spacer rows in Table

      // TableRow is not findable; verify via the cell key instead.
      final cell00Finder = find.byKey(AdaptiveTable.cellKey(tableKey, 0, 0));
      expect(cell00Finder, findsOneWidget);
    });

    testWidgets('applies verticalCellContentAlignment', (tester) async {
      final cardMap = {
        'type': 'AdaptiveCard',
        'version': '1.5',
        'body': [
          {
            'id': 'testTable',
            'type': 'Table',
            'verticalCellContentAlignment': 'top',
            'columns': [
              {'width': 1},
            ],
            'rows': [
              {
                'type': 'TableRow',
                'cells': [
                  {
                    'type': 'TableCell',
                    'items': [
                      {'type': 'TextBlock', 'text': 'Cell'},
                    ],
                  },
                ],
              },
            ],
          },
        ],
      };

      await tester.pumpWidget(
        getTestWidgetFromMap(
          map: cardMap,
          title: 'Vertical Alignment Test',
        ),
      );

      await tester.pumpAndSettle();

      const tableKey = 'testTable_adaptive';
      final containerFinder = find.byKey(AdaptiveTable.cellKey(tableKey, 0, 0));
      final container = tester.widget<Container>(containerFinder);
      final align = container.child! as Align;
      expect(align.alignment, Alignment.topLeft); // 'top' -> topLeft
    });

    testWidgets('maps column widths onto Table.columnWidths', (tester) async {
      final cardMap = {
        'type': 'AdaptiveCard',
        'version': '1.5',
        'body': [
          {
            'type': 'Table',
            'id': 'testTable',
            'columns': [
              {'width': 1},
              {'width': 2},
              {'width': 'auto'},
              {'width': '40px'},
            ],
            'rows': [
              {
                'type': 'TableRow',
                'cells': [
                  {
                    'type': 'TableCell',
                    'items': [
                      {'type': 'TextBlock', 'text': 'a'},
                    ],
                  },
                  {
                    'type': 'TableCell',
                    'items': [
                      {'type': 'TextBlock', 'text': 'b'},
                    ],
                  },
                  {
                    'type': 'TableCell',
                    'items': [
                      {'type': 'TextBlock', 'text': 'c'},
                    ],
                  },
                  {
                    'type': 'TableCell',
                    'items': [
                      {'type': 'TextBlock', 'text': 'd'},
                    ],
                  },
                ],
              },
            ],
          },
        ],
      };

      await tester.pumpWidget(
        getTestWidgetFromMap(map: cardMap, title: 'Column Widths Test'),
      );
      await tester.pumpAndSettle();

      // TableColumnWidth subclasses don't override `==`; assert type + value.
      final table = tester.widget<Table>(find.byType(Table));
      expect(
        table.columnWidths![0],
        isA<FlexColumnWidth>().having((w) => w.value, 'value', 1.0),
      );
      expect(
        table.columnWidths![1],
        isA<FlexColumnWidth>().having((w) => w.value, 'value', 2.0),
      );
      expect(table.columnWidths![2], isA<IntrinsicColumnWidth>());
      expect(
        table.columnWidths![3],
        isA<FixedColumnWidth>().having((w) => w.value, 'value', 40.0),
      );
    });

    testWidgets('applies firstRowAsHeader with bold styling', (tester) async {
      final cardMap = {
        'type': 'AdaptiveCard',
        'version': '1.5',
        'body': [
          {
            'type': 'Table',
            'columns': [
              {'width': 1},
            ],
            'rows': [
              {
                'type': 'TableRow',
                'cells': [
                  {
                    'type': 'TableCell',
                    'items': [
                      {'type': 'TextBlock', 'text': 'Header'},
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
                      {'type': 'TextBlock', 'text': 'Data'},
                    ],
                  },
                ],
              },
            ],
          },
        ],
      };

      await tester.pumpWidget(
        getTestWidgetFromMap(
          map: cardMap,
          title: 'First Row As Header Test',
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Header'), findsOneWidget);
      expect(find.text('Data'), findsOneWidget);
      // firstRowAsHeader bakes the columnHeader weight (bolder) into the header
      // cell's TextBlock map; the body row's TextBlock keeps no explicit
      // weight.
      final headerBlock = tester.widget<AdaptiveTextBlock>(
        find.ancestor(
          of: find.text('Header'),
          matching: find.byType(AdaptiveTextBlock),
        ),
      );
      final bodyBlock = tester.widget<AdaptiveTextBlock>(
        find.ancestor(
          of: find.text('Data'),
          matching: find.byType(AdaptiveTextBlock),
        ),
      );
      expect(bodyBlock.adaptiveMap['weight'], isNull);
      expect(
        headerBlock.adaptiveMap['weight'].toString().toLowerCase(),
        'bolder',
      );
    });

    testWidgets('applies background color from cell style', (tester) async {
      final cardMap = {
        'type': 'AdaptiveCard',
        'version': '1.5',
        'body': [
          {
            'id': 'testTable',
            'type': 'Table',
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
                    'style': 'good',
                    'items': [
                      {'type': 'TextBlock', 'text': 'Good Cell'},
                    ],
                  },
                  {
                    'type': 'TableCell',
                    'style': 'attention',
                    'items': [
                      {'type': 'TextBlock', 'text': 'Attention Cell'},
                    ],
                  },
                ],
              },
            ],
          },
        ],
      };

      await tester.pumpWidget(
        getTestWidgetFromMap(
          map: cardMap,
          title: 'Table Cell Style Test',
        ),
      );

      await tester.pumpAndSettle();

      const tableKey = 'testTable_adaptive';

      // Verify "good" style (green)
      // Find the Container that wraps the Align that wraps the content
      final goodContainerFinder = find.byKey(
        AdaptiveTable.cellKey(tableKey, 0, 0),
      );
      final goodContainer = tester.widget<Container>(goodContainerFinder);
      final goodDecoration = goodContainer.decoration! as BoxDecoration;
      expect(
        goodDecoration.color,
        themeContainerStyles.good!.backgroundColor,
      );

      // Verify "attention" style (red)
      final attentionContainerFinder = find.byKey(
        AdaptiveTable.cellKey(tableKey, 0, 1),
      );
      final attentionContainer = tester.widget<Container>(
        attentionContainerFinder,
      );
      final attentionDecoration =
          attentionContainer.decoration! as BoxDecoration;
      expect(
        attentionDecoration.color,
        themeContainerStyles.attention!.backgroundColor,
      );
    });

    testWidgets('applies background color from row style fallback', (
      tester,
    ) async {
      final cardMap = {
        'type': 'AdaptiveCard',
        'version': '1.5',
        'body': [
          {
            'id': 'testTable',
            'type': 'Table',
            'columns': [
              {'width': 1},
            ],
            'rows': [
              {
                'type': 'TableRow',
                'style': 'warning',
                'cells': [
                  {
                    'type': 'TableCell',
                    'items': [
                      {'type': 'TextBlock', 'text': 'Warning Cell'},
                    ],
                  },
                ],
              },
            ],
          },
        ],
      };

      await tester.pumpWidget(
        getTestWidgetFromMap(
          map: cardMap,
          title: 'Row Style Fallback Test',
        ),
      );

      await tester.pumpAndSettle();

      const tableKey = 'testTable_adaptive';
      final warningContainerFinder = find.byKey(
        AdaptiveTable.cellKey(tableKey, 0, 0),
      );
      final warningContainer = tester.widget<Container>(warningContainerFinder);
      expect(
        warningContainer,
        isNotNull,
        reason: 'Warning container not found',
      );
      final warningDecoration = warningContainer.decoration as BoxDecoration?;
      expect(
        warningDecoration,
        isNotNull,
        reason: 'Warning decoration not found',
      );
      expect(
        warningDecoration?.color,
        themeContainerStyles.warning!.backgroundColor,
      );
    });

    testWidgets('auto column has the same width across rows', (tester) async {
      final cardMap = {
        'type': 'AdaptiveCard',
        'version': '1.5',
        'body': [
          {
            'type': 'Table',
            'id': 'testTable',
            'columns': [
              {'width': 'auto'},
              {'width': 'stretch'},
            ],
            'rows': [
              {
                'type': 'TableRow',
                'cells': [
                  {
                    'type': 'TableCell',
                    'items': [
                      {'type': 'TextBlock', 'text': 'X'},
                    ],
                  },
                  {
                    'type': 'TableCell',
                    'items': [
                      {'type': 'TextBlock', 'text': 'short'},
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
                      {'type': 'TextBlock', 'text': 'a much longer label'},
                    ],
                  },
                  {
                    'type': 'TableCell',
                    'items': [
                      {'type': 'TextBlock', 'text': 'short'},
                    ],
                  },
                ],
              },
            ],
          },
        ],
      };

      await tester.pumpWidget(
        getTestWidgetFromMap(map: cardMap, title: 'Auto Width Test'),
      );
      await tester.pumpAndSettle();

      const tableKey = 'testTable_adaptive';
      final col0Row0 = tester.getSize(
        find.byKey(AdaptiveTable.cellKey(tableKey, 0, 0)),
      );
      final col0Row1 = tester.getSize(
        find.byKey(AdaptiveTable.cellKey(tableKey, 1, 0)),
      );
      // Auto column is sized to the widest cell content across all rows.
      expect(col0Row0.width, col0Row1.width);
    });

    testWidgets('stretch column consumes width beyond the auto column', (
      tester,
    ) async {
      final cardMap = {
        'type': 'AdaptiveCard',
        'version': '1.5',
        'body': [
          {
            'type': 'Table',
            'id': 'testTable',
            'columns': [
              {'width': 'auto'},
              {'width': 'stretch'},
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
            ],
          },
        ],
      };

      await tester.pumpWidget(
        getTestWidgetFromMap(map: cardMap, title: 'Stretch Width Test'),
      );
      await tester.pumpAndSettle();

      const tableKey = 'testTable_adaptive';
      final autoCell = tester.getSize(
        find.byKey(AdaptiveTable.cellKey(tableKey, 0, 0)),
      );
      final stretchCell = tester.getSize(
        find.byKey(AdaptiveTable.cellKey(tableKey, 0, 1)),
      );
      // The single-character "auto" column is far narrower than the stretch
      // one.
      expect(stretchCell.width, greaterThan(autoCell.width));
    });

    testWidgets('cell minHeight raises the row height', (tester) async {
      final cardMap = {
        'type': 'AdaptiveCard',
        'version': '1.5',
        'body': [
          {
            'type': 'Table',
            'id': 'testTable',
            'columns': [
              {'width': 'stretch'},
            ],
            'rows': [
              {
                'type': 'TableRow',
                'cells': [
                  {
                    'type': 'TableCell',
                    'minHeight': '120px',
                    'items': [
                      {'type': 'TextBlock', 'text': 'tall'},
                    ],
                  },
                ],
              },
            ],
          },
        ],
      };

      await tester.pumpWidget(
        getTestWidgetFromMap(map: cardMap, title: 'MinHeight Test'),
      );
      await tester.pumpAndSettle();

      const tableKey = 'testTable_adaptive';
      final cell = tester.getSize(
        find.byKey(AdaptiveTable.cellKey(tableKey, 0, 0)),
      );
      expect(cell.height, greaterThanOrEqualTo(120.0));
    });

    testWidgets('cell backgroundImage renders a DecorationImage', (
      tester,
    ) async {
      final cardMap = {
        'type': 'AdaptiveCard',
        'version': '1.5',
        'body': [
          {
            'type': 'Table',
            'id': 'testTable',
            'columns': [
              {'width': 'stretch'},
            ],
            'rows': [
              {
                'type': 'TableRow',
                'cells': [
                  {
                    'type': 'TableCell',
                    'backgroundImage': 'https://example.com/bg.png',
                    'items': [
                      {'type': 'TextBlock', 'text': 'bg'},
                    ],
                  },
                ],
              },
            ],
          },
        ],
      };

      await tester.pumpWidget(
        getTestWidgetFromMap(map: cardMap, title: 'Cell Background Image Test'),
      );
      await tester.pumpAndSettle();

      const tableKey = 'testTable_adaptive';
      final container = tester.widget<Container>(
        find.byKey(AdaptiveTable.cellKey(tableKey, 0, 0)),
      );
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.image, isNotNull);
    });

    testWidgets('ragged rows (fewer cells than columns) render without error', (
      tester,
    ) async {
      final cardMap = {
        'type': 'AdaptiveCard',
        'version': '1.5',
        'body': [
          {
            'type': 'Table',
            'id': 'testTable',
            'columns': [
              {'width': 'stretch'},
              {'width': 'stretch'},
            ],
            'rows': [
              {
                'type': 'TableRow',
                'cells': [
                  {
                    'type': 'TableCell',
                    'items': [
                      {'type': 'TextBlock', 'text': 'one'},
                    ],
                  },
                ],
              },
            ],
          },
        ],
      };

      await tester.pumpWidget(
        getTestWidgetFromMap(map: cardMap, title: 'Ragged Rows Test'),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(Table), findsOneWidget);
      expect(find.text('one'), findsOneWidget);
    });

    testWidgets('showGridLines true draws a TableBorder', (tester) async {
      final cardMap = {
        'type': 'AdaptiveCard',
        'version': '1.5',
        'body': [
          {
            'type': 'Table',
            'id': 'testTable',
            'showGridLines': true,
            'columns': [
              {'width': 'stretch'},
            ],
            'rows': [
              {
                'type': 'TableRow',
                'cells': [
                  {
                    'type': 'TableCell',
                    'items': [
                      {'type': 'TextBlock', 'text': 'g'},
                    ],
                  },
                ],
              },
            ],
          },
        ],
      };

      await tester.pumpWidget(
        getTestWidgetFromMap(map: cardMap, title: 'Grid Lines Test'),
      );
      await tester.pumpAndSettle();

      final table = tester.widget<Table>(find.byType(Table));
      expect(table.border, isNotNull);
    });
  });
}
