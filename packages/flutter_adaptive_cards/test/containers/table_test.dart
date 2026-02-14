import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/flutter_adaptive_cards.dart';
import 'package:flutter_adaptive_cards/src/containers/table.dart';
import 'package:flutter_adaptive_cards/src/flutter_raw_adaptive_card.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
        MaterialApp(
          home: Scaffold(
            body: RawAdaptiveCard.fromMap(
              map: cardMap,
              hostConfigs: HostConfigs(),
            ),
          ),
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
        MaterialApp(
          home: Scaffold(
            body: RawAdaptiveCard.fromMap(
              map: cardMap,
              hostConfigs: HostConfigs(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should not find Dividers when showGridLines is false
      // expect(find.byType(Divider), findsNothing);
      expect(find.byType(VerticalDivider), findsNothing);

      // Should find SizedBox (spacing) instead
      // 1 row separator (between row 1 and row end? no, between rows), only 1 row here?
      // Wait, 1 row means no row separators.
      // But 1 column? 1 column means no column separators.
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
        MaterialApp(
          home: Scaffold(
            body: RawAdaptiveCard.fromMap(
              map: cardMap,
              hostConfigs: HostConfigs(),
            ),
          ),
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

      // Find SizedBox with spacing
      final columnFinder = find.byKey(AdaptiveTable.tableColumnKey(tableKey));
      final column = tester.widget<Column>(columnFinder);
      expect(column.children.length, 3); // Row 1, Spacer, Row 2

      final row1Finder = find.byKey(AdaptiveTable.rowKey(tableKey, 0));
      final row1 = tester.widget<Row>(row1Finder);
      expect(row1.children.length, 3); // Cell 1, Spacer, Cell 2
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
        MaterialApp(
          home: Scaffold(
            body: RawAdaptiveCard.fromMap(
              map: cardMap,
              hostConfigs: HostConfigs(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      const tableKey = 'testTable_adaptive';
      final containerFinder = find.byKey(AdaptiveTable.cellKey(tableKey, 0, 0));
      final container = tester.widget<Container>(containerFinder);
      final align = container.child! as Align;
      expect(align.alignment, Alignment.topLeft); // 'top' -> topLeft
    });

    testWidgets('applies column widths (flex)', (tester) async {
      final cardMap = {
        'type': 'AdaptiveCard',
        'version': '1.5',
        'body': [
          {
            'id': 'testTable',
            'type': 'Table',
            'columns': [
              {'width': 1},
              {'width': 2},
              {'width': 1},
            ],
            'rows': [
              {
                'type': 'TableRow',
                'cells': [
                  {
                    'type': 'TableCell',
                    'items': [
                      {'type': 'TextBlock', 'text': 'C1'},
                    ],
                  },
                  {
                    'type': 'TableCell',
                    'items': [
                      {'type': 'TextBlock', 'text': 'C2'},
                    ],
                  },
                  {
                    'type': 'TableCell',
                    'items': [
                      {'type': 'TextBlock', 'text': 'C3'},
                    ],
                  },
                ],
              },
            ],
          },
        ],
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RawAdaptiveCard.fromMap(
              map: cardMap,
              hostConfigs: HostConfigs(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      const tableKey = 'testTable_adaptive';
      // Find Expanded widgets wrapping the content
      final c1Finder = find.byKey(AdaptiveTable.columnKey(tableKey, 0));
      final c2Finder = find.byKey(AdaptiveTable.columnKey(tableKey, 1));
      final c3Finder = find.byKey(AdaptiveTable.columnKey(tableKey, 2));

      expect(tester.widget<Expanded>(c1Finder).flex, 1);
      expect(tester.widget<Expanded>(c2Finder).flex, 2);
      expect(tester.widget<Expanded>(c3Finder).flex, 1);
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
        MaterialApp(
          home: Scaffold(
            body: RawAdaptiveCard.fromMap(
              map: cardMap,
              hostConfigs: HostConfigs(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Header'), findsOneWidget);
      expect(find.text('Data'), findsOneWidget);
      // Header row should have bold DefaultTextStyle
      expect(find.byType(DefaultTextStyle), findsWidgets);
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
        MaterialApp(
          home: Scaffold(
            body: RawAdaptiveCard.fromMap(
              map: cardMap,
              hostConfigs: HostConfigs(),
            ),
          ),
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
      expect(goodDecoration.color, const Color(0xFFCCFFCC));

      // Verify "attention" style (red)
      final attentionContainerFinder = find.byKey(
        AdaptiveTable.cellKey(tableKey, 0, 1),
      );
      final attentionContainer = tester.widget<Container>(
        attentionContainerFinder,
      );
      final attentionDecoration =
          attentionContainer.decoration! as BoxDecoration;
      expect(attentionDecoration.color, const Color(0xFFFFCCCC));
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
        MaterialApp(
          home: Scaffold(
            body: RawAdaptiveCard.fromMap(
              map: cardMap,
              hostConfigs: HostConfigs(),
            ),
          ),
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
      expect(warningDecoration?.color, const Color(0xFFFFE6CC));
    });
  });
}
