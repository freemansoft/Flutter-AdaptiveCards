import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/host_config.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/theme_color_fallbacks.dart';
import 'package:flutter_adaptive_cards_fs/src/reference_resolver.dart';
import 'package:flutter_adaptive_cards_fs/src/responsive/adaptive_area_grid.dart';
import 'package:flutter_adaptive_cards_fs/src/responsive/area_grid_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final resolver = ReferenceResolver(
    hostConfigs: HostConfigs(),
    colorFallbacks: ThemeColorFallbacks(ThemeData.light()),
  );

  Widget host(Widget child, {double width = 400}) => MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(width: width, child: child),
          ),
        ),
      );

  AreaGridLayout twoColLayout() => AreaGridLayout.fromMap(const {
        'type': 'Layout.AreaGrid',
        'columns': [50, 50],
        // 'none' so column widths are exactly 50% of 400 (no default gap).
        'columnSpacing': 'none',
        'areas': [
          {'name': 'left', 'column': 1},
          {'name': 'right', 'column': 2},
        ],
      });

  testWidgets('places children side-by-side by grid.area', (tester) async {
    await tester.pumpWidget(host(
      AdaptiveAreaGrid(
        layout: twoColLayout(),
        styleResolver: resolver,
        childMaps: const [
          {'grid.area': 'left'},
          {'grid.area': 'right'},
        ],
        children: const [
          SizedBox(key: Key('l'), height: 30),
          SizedBox(key: Key('r'), height: 50),
        ],
      ),
    ));
    final l = tester.getTopLeft(find.byKey(const Key('l')));
    final r = tester.getTopLeft(find.byKey(const Key('r')));
    expect(l.dy, r.dy); // same row
    expect(r.dx, greaterThan(l.dx)); // right is to the right
    expect(tester.getSize(find.byKey(const Key('l'))).width, 200); // 50% of 400
  });

  testWidgets('height:stretch child fills its row band', (tester) async {
    await tester.pumpWidget(host(
      AdaptiveAreaGrid(
        layout: twoColLayout(),
        styleResolver: resolver,
        childMaps: const [
          {'grid.area': 'left', 'height': 'stretch'},
          {'grid.area': 'right'},
        ],
        children: const [
          SizedBox(key: Key('l'), height: 10),
          SizedBox(key: Key('r'), height: 80),
        ],
      ),
    ));
    // The stretch cell grows to the row height set by the taller sibling (80).
    expect(tester.getSize(find.byKey(const Key('l'))).height, 80);
  });

  testWidgets('unplaced/unknown grid.area renders in fallback stack',
      (tester) async {
    await tester.pumpWidget(host(
      AdaptiveAreaGrid(
        layout: twoColLayout(),
        styleResolver: resolver,
        childMaps: const [
          {'grid.area': 'left'},
          {'grid.area': 'nope'}, // unknown
          {}, // no grid.area
        ],
        children: const [
          SizedBox(key: Key('l'), height: 10),
          Text('orphan1'),
          Text('orphan2'),
        ],
      ),
    ));
    expect(tester.takeException(), isNull);
    expect(find.text('orphan1'), findsOneWidget);
    expect(find.text('orphan2'), findsOneWidget);
  });

  testWidgets('columnSpan widens a cell across columns', (tester) async {
    final layout = AreaGridLayout.fromMap(const {
      'type': 'Layout.AreaGrid',
      'columns': [50, 50],
      'columnSpacing': 'none',
      'areas': [
        {'name': 'wide', 'column': 1, 'columnSpan': 2},
      ],
    });
    await tester.pumpWidget(host(
      AdaptiveAreaGrid(
        layout: layout,
        styleResolver: resolver,
        childMaps: const [
          {'grid.area': 'wide'},
        ],
        children: const [SizedBox(key: Key('w'), height: 20)],
      ),
    ));
    // Spans both 50% columns of 400 → 400.
    expect(tester.getSize(find.byKey(const Key('w'))).width, 400);
  });

  testWidgets('rowSpan grows spanned rows so a tall child fits', (tester) async {
    final layout = AreaGridLayout.fromMap(const {
      'type': 'Layout.AreaGrid',
      'columns': [50, 50],
      'columnSpacing': 'none',
      'rowSpacing': 'none',
      'areas': [
        {'name': 'tall', 'column': 1, 'row': 1, 'rowSpan': 2},
        {'name': 'a', 'column': 2, 'row': 1},
        {'name': 'b', 'column': 2, 'row': 2},
      ],
    });
    await tester.pumpWidget(host(
      AdaptiveAreaGrid(
        layout: layout,
        styleResolver: resolver,
        childMaps: const [
          {'grid.area': 'tall', 'height': 'stretch'},
          {'grid.area': 'a'},
          {'grid.area': 'b'},
        ],
        children: const [
          SizedBox(key: Key('tall'), height: 10),
          SizedBox(key: Key('a'), height: 30),
          SizedBox(key: Key('b'), height: 30),
        ],
      ),
    ));
    // Rows seeded at 30 each (from a/b); the stretch 'tall' fills both → 60.
    expect(tester.getSize(find.byKey(const Key('tall'))).height, 60);
  });

  testWidgets('multi-row non-stretch child grows its spanned rows',
      (tester) async {
    final layout = AreaGridLayout.fromMap(const {
      'type': 'Layout.AreaGrid',
      'columns': [50, 50],
      'columnSpacing': 'none',
      'rowSpacing': 'none',
      'areas': [
        {'name': 'tall', 'column': 1, 'row': 1, 'rowSpan': 2},
        {'name': 'a', 'column': 2, 'row': 1},
        {'name': 'b', 'column': 2, 'row': 2},
      ],
    });
    await tester.pumpWidget(host(
      AdaptiveAreaGrid(
        layout: layout,
        styleResolver: resolver,
        childMaps: const [
          {'grid.area': 'tall'}, // non-stretch, taller than its two rows
          {'grid.area': 'a'},
          {'grid.area': 'b'},
        ],
        children: const [
          SizedBox(key: Key('tall'), height: 200),
          SizedBox(key: Key('a'), height: 30),
          SizedBox(key: Key('b'), height: 30),
        ],
      ),
    ));
    // The grid must be at least as tall as the 200px spanning child.
    expect(
      tester.getSize(find.byType(AdaptiveAreaGrid)).height,
      greaterThanOrEqualTo(200),
    );
  });

  testWidgets('updateRenderObject reflows when the layout changes',
      (tester) async {
    await tester.pumpWidget(host(
      AdaptiveAreaGrid(
        layout: twoColLayout(),
        styleResolver: resolver,
        childMaps: const [
          {'grid.area': 'left'},
          {'grid.area': 'right'},
        ],
        children: const [
          SizedBox(key: Key('l'), height: 30),
          SizedBox(key: Key('r'), height: 30),
        ],
      ),
    ));
    expect(tester.getSize(find.byKey(const Key('l'))).width, 200);

    // Re-pump with 70/30 columns; the render object is reused (updateRenderObject).
    final lopsided = AreaGridLayout.fromMap(const {
      'type': 'Layout.AreaGrid',
      'columns': [70, 30],
      'columnSpacing': 'none',
      'areas': [
        {'name': 'left', 'column': 1},
        {'name': 'right', 'column': 2},
      ],
    });
    await tester.pumpWidget(host(
      AdaptiveAreaGrid(
        layout: lopsided,
        styleResolver: resolver,
        childMaps: const [
          {'grid.area': 'left'},
          {'grid.area': 'right'},
        ],
        children: const [
          SizedBox(key: Key('l'), height: 30),
          SizedBox(key: Key('r'), height: 30),
        ],
      ),
    ));
    expect(tester.getSize(find.byKey(const Key('l'))).width, 280); // 70% of 400
  });
}
