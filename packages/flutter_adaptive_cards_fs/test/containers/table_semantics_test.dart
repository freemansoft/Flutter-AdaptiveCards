import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

/// Accessibility semantics for `Table`.
///
/// Flutter's [Table] exposes no row/column association, so without these
/// annotations a screen reader reads every body cell as a context-free value
/// ("Delayed") and cannot tell a header cell from a data cell.
void main() {
  setUp(() {
    HttpOverrides.global = MyTestHttpOverrides();
  });

  Widget buildCard(Map<String, dynamic> el) => getTestWidgetFromMap(
    map: {
      'type': 'AdaptiveCard',
      'version': '1.5',
      'body': [el],
    },
    title: 'a test',
    onOpenUrl: (_) {},
    onSubmit: (_) {},
    onExecute: (_) {},
  );

  Map<String, dynamic> cell(List<Map<String, dynamic>> items) => {
    'type': 'TableCell',
    'items': items,
  };

  Map<String, dynamic> textCell(String text) => cell([
    {'type': 'TextBlock', 'text': text},
  ]);

  Map<String, dynamic> table({
    bool? firstRowAsHeader,
    List<Map<String, dynamic>>? headerCells,
    List<Map<String, dynamic>>? bodyCells,
  }) => {
    'type': 'Table',
    'id': 'flights',
    'firstRowAsHeader': ?firstRowAsHeader,
    'columns': [
      {'width': 1},
      {'width': 1},
    ],
    'rows': [
      {
        'type': 'TableRow',
        'cells':
            headerCells ?? [textCell('Flight'), textCell('Status')],
      },
      {
        'type': 'TableRow',
        'cells': bodyCells ?? [textCell('UA123'), textCell('Delayed')],
      },
    ],
  };

  testWidgets('header row cells are exposed as headers', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(buildCard(table()));
    await tester.pumpAndSettle();

    expect(
      tester.getSemantics(find.text('Status')).getSemanticsData()
          .flagsCollection
          .isHeader,
      isTrue,
    );
    // A body cell must not be mistaken for a header.
    expect(
      tester.getSemantics(find.text('Delayed')).getSemanticsData()
          .flagsCollection
          .isHeader,
      isFalse,
    );

    handle.dispose();
  });

  testWidgets('body cell is announced with its column header', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(buildCard(table()));
    await tester.pumpAndSettle();

    final label = tester
        .getSemantics(find.text('Delayed'))
        .getSemanticsData()
        .label;

    expect(label, contains('Status'));
    expect(label, contains('Delayed'));
    // The header of a *different* column must not leak into this cell.
    expect(label, isNot(contains('Flight')));

    handle.dispose();
  });

  testWidgets('no header association when firstRowAsHeader is false', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(buildCard(table(firstRowAsHeader: false)));
    await tester.pumpAndSettle();

    final data = tester.getSemantics(find.text('Delayed')).getSemanticsData();
    expect(data.flagsCollection.isHeader, isFalse);
    expect(data.label, isNot(contains('Status')));

    handle.dispose();
  });

  testWidgets('header cell with no text does not label its column', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      buildCard(
        table(
          // An image-only header has nothing to speak; the column must simply
          // go unlabeled rather than gain an empty or placeholder name.
          headerCells: [
            textCell('Flight'),
            cell([
              {'type': 'Image', 'url': 'https://example.com/icon.png'},
            ]),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.getSemantics(find.text('Delayed')).getSemanticsData().label,
      'Delayed',
    );

    handle.dispose();
  });

  testWidgets('a selectAction cell stays an independently focusable button', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      buildCard(
        table(
          bodyCells: [
            textCell('UA123'),
            {
              'type': 'TableCell',
              'items': [
                {'type': 'TextBlock', 'text': 'Delayed'},
              ],
              'selectAction': {
                'type': 'Action.OpenUrl',
                'title': 'Details',
                'url': 'https://example.com',
              },
            },
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Header association must not collapse the cell's interactive node: the
    // tappable is still its own button node.
    final data = tester.getSemantics(find.text('Delayed')).getSemanticsData();
    expect(data.flagsCollection.isButton, isTrue);
    expect(data.label, contains('Status'));

    handle.dispose();
  });
}
