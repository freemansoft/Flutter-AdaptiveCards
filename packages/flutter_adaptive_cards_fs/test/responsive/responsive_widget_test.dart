import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/responsive/adaptive_area_grid.dart';
import 'package:flutter_adaptive_cards_fs/src/responsive/adaptive_flow_layout.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

/// Loads a card fixture from `test/samples/<path>` as a JSON map.
Map<String, dynamic> _loadCard(String path) {
  final raw = File('test/samples/$path').readAsStringSync();
  return json.decode(raw) as Map<String, dynamic>;
}

/// Renders [card] via the canonical test harness at a controlled card width.
///
/// The harness centers the card with loose constraints, so the card's measured
/// width equals the test surface width. We pin devicePixelRatio to 1.0 so the
/// logical width equals the value passed here, and reset both in tearDown.
Future<void> _pumpCardAtWidth(
  WidgetTester tester,
  Map<String, dynamic> card,
  double width,
) async {
  tester.view.devicePixelRatio = 1.0;
  await tester.binding.setSurfaceSize(Size(width, 1200));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    getTestWidgetFromMap(map: card, title: 'responsive test'),
  );
  await tester.pumpAndSettle();
}

Map<String, dynamic> _tableFlowCard() => {
  'type': 'AdaptiveCard',
  'version': '1.6',
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
              'layouts': [
                {
                  'type': 'Layout.Flow',
                  'targetWidth': 'atLeast:standard',
                },
              ],
              'items': [
                {'type': 'TextBlock', 'text': 'CellOne'},
                {'type': 'TextBlock', 'text': 'CellTwo'},
              ],
            },
          ],
        },
      ],
    },
  ],
};

// A ColumnSet is a genuinely height-bounded context (columns share an equal row
// band via IntrinsicHeight), so a `height: "stretch"` child there fills the
// band. (A standalone `minHeight` Container under the unbounded card-root
// Column is NOT bounded — its child degrades to auto, per the design.)
Map<String, dynamic> _stretchColumnSetCard() => {
  'type': 'AdaptiveCard',
  'version': '1.6',
  'body': [
    {
      'type': 'ColumnSet',
      'columns': [
        {
          'type': 'Column',
          'width': 'stretch',
          'items': [
            {
              'type': 'Container',
              'minHeight': '300px',
              'items': <Map<String, dynamic>>[],
            },
          ],
        },
        {
          'type': 'Column',
          'width': 'stretch',
          'items': [
            {'type': 'TextBlock', 'text': 'top'},
            {
              'type': 'Container',
              'height': 'stretch',
              'items': [
                {'type': 'TextBlock', 'text': 'filler'},
              ],
            },
          ],
        },
      ],
    },
  ],
};

Map<String, dynamic> _areaGridCard() => {
  'type': 'AdaptiveCard',
  'version': '1.6',
  'layouts': [
    {
      'type': 'Layout.AreaGrid',
      'targetWidth': 'atLeast:standard',
      'columns': [50, 50],
      'areas': [
        {'name': 'l', 'column': 1},
        {'name': 'r', 'column': 2},
      ],
    },
  ],
  'body': [
    {'type': 'TextBlock', 'text': 'L', 'grid.area': 'l'},
    {'type': 'TextBlock', 'text': 'R', 'grid.area': 'r'},
  ],
};

void main() {
  final targetWidthCard = _loadCard('responsive/target_width.json');
  final flowCard = _loadCard('responsive/flow_container.json');
  final rootFlowCard = _loadCard('responsive/flow_root.json');
  final flowColumnCard = _loadCard('responsive/flow_column.json');

  testWidgets('targetWidth hides element when card is narrow', (tester) async {
    await _pumpCardAtWidth(tester, targetWidthCard, 150);
    expect(find.text('always'), findsOneWidget);
    expect(find.text('wide-only'), findsNothing);
  });

  testWidgets('targetWidth shows element when card is wide', (tester) async {
    await _pumpCardAtWidth(tester, targetWidthCard, 1000);
    expect(find.text('always'), findsOneWidget);
    expect(find.text('wide-only'), findsOneWidget);
  });

  testWidgets('Container uses Flow when wide', (tester) async {
    await _pumpCardAtWidth(tester, flowCard, 1000);
    expect(find.byType(AdaptiveFlowLayout), findsOneWidget);
    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Beta'), findsOneWidget);
  });

  testWidgets('Container stays a stack when narrow', (tester) async {
    await _pumpCardAtWidth(tester, flowCard, 150);
    expect(find.byType(AdaptiveFlowLayout), findsNothing);
    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Beta'), findsOneWidget);
  });

  testWidgets('Flow items sit side-by-side when wide (not full-width stack)', (
    tester,
  ) async {
    await _pumpCardAtWidth(tester, flowCard, 1000);
    // Same row (equal dy), different columns (different dx): items size to
    // content and flow, rather than each expanding to the full row width.
    final alpha = tester.getTopLeft(find.text('Alpha'));
    final beta = tester.getTopLeft(find.text('Beta'));
    expect(alpha.dy, beta.dy);
    expect(alpha.dx, isNot(beta.dx));
  });

  testWidgets('root body uses Flow when wide', (tester) async {
    await _pumpCardAtWidth(tester, rootFlowCard, 1000);
    expect(find.byType(AdaptiveFlowLayout), findsOneWidget);
    expect(find.text('rootOne'), findsOneWidget);
    expect(find.text('rootTwo'), findsOneWidget);
  });

  testWidgets('root body stays a stack when narrow', (tester) async {
    await _pumpCardAtWidth(tester, rootFlowCard, 150);
    expect(find.byType(AdaptiveFlowLayout), findsNothing);
    expect(find.text('rootOne'), findsOneWidget);
    expect(find.text('rootTwo'), findsOneWidget);
  });

  testWidgets('Column uses Flow when wide', (tester) async {
    await _pumpCardAtWidth(tester, flowColumnCard, 1000);
    expect(find.byType(AdaptiveFlowLayout), findsOneWidget);
    expect(find.text('One'), findsOneWidget);
    expect(find.text('Three'), findsOneWidget);
  });

  testWidgets('Column stays a stack when narrow', (tester) async {
    await _pumpCardAtWidth(tester, flowColumnCard, 150);
    expect(find.byType(AdaptiveFlowLayout), findsNothing);
    expect(find.text('One'), findsOneWidget);
    expect(find.text('Three'), findsOneWidget);
  });

  testWidgets('TableCell uses Flow when wide', (tester) async {
    await _pumpCardAtWidth(tester, _tableFlowCard(), 1000);
    expect(find.byType(AdaptiveFlowLayout), findsOneWidget);
    expect(find.text('CellOne'), findsOneWidget);
  });

  testWidgets('TableCell stays non-Flow when narrow', (tester) async {
    await _pumpCardAtWidth(tester, _tableFlowCard(), 150);
    expect(find.byType(AdaptiveFlowLayout), findsNothing);
    expect(find.text('CellOne'), findsOneWidget);
  });

  testWidgets('root body uses AreaGrid when wide', (tester) async {
    await _pumpCardAtWidth(tester, _areaGridCard(), 1000);
    expect(find.byType(AdaptiveAreaGrid), findsOneWidget);
    final l = tester.getTopLeft(find.text('L'));
    final r = tester.getTopLeft(find.text('R'));
    expect(l.dy, r.dy);
    expect(r.dx, greaterThan(l.dx));
  });

  testWidgets('root body stacks (no AreaGrid) when narrow', (tester) async {
    await _pumpCardAtWidth(tester, _areaGridCard(), 150);
    expect(find.byType(AdaptiveAreaGrid), findsNothing);
    expect(find.text('L'), findsOneWidget);
    expect(find.text('R'), findsOneWidget);
  });

  testWidgets('height:stretch inside a ColumnSet renders without throwing', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(600, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      getTestWidgetFromMap(map: _stretchColumnSetCard(), title: 'stretch'),
    );
    await tester.pumpAndSettle();
    // The regression this guards: a stretch child inside ColumnSet's
    // IntrinsicHeight must not throw (a LayoutBuilder-based stack would).
    expect(tester.takeException(), isNull);
    expect(find.text('top'), findsOneWidget);
    expect(find.text('filler'), findsOneWidget);
    // The ColumnSet row band is at least the first column's 300px minHeight.
    expect(
      tester.getSize(find.byType(IntrinsicHeight).first).height,
      greaterThanOrEqualTo(300),
    );
  });
}
