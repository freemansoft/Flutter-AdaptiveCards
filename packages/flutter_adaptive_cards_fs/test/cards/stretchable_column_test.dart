import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/cards/stretchable_column.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host({required double? maxHeight, required List<Widget> child}) {
    final content = child.single;
    return MaterialApp(
      home: Scaffold(
        // A scroll view gives its child an unbounded maxHeight; a bounded
        // ConstrainedBox provides the finite-height case. (An Align inside a
        // Scaffold would cap maxHeight to the finite surface, so it cannot
        // model the unbounded case.)
        body: maxHeight == null
            ? SingleChildScrollView(
                child: SizedBox(width: 300, child: content),
              )
            : Align(
                alignment: Alignment.topLeft,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: maxHeight,
                    maxWidth: 300,
                  ),
                  child: content,
                ),
              ),
      ),
    );
  }

  testWidgets('bounded height: single stretch child fills height',
      (tester) async {
    await tester.pumpWidget(
      host(
        maxHeight: 600,
        child: [
          buildStretchableColumn(
            childMaps: const [
              {'type': 'X', 'height': 'stretch'},
            ],
            children: const [SizedBox(key: Key('s'), height: 10)],
            mainAxisAlignment: MainAxisAlignment.start,
          ),
        ],
      ),
    );
    // The stretch child is forced to the full bounded height.
    expect(tester.getSize(find.byKey(const Key('s'))).height, 600);
  });

  testWidgets('bounded height: two stretch children split the height',
      (tester) async {
    await tester.pumpWidget(
      host(
        maxHeight: 600,
        child: [
          buildStretchableColumn(
            childMaps: const [
              {'type': 'X', 'height': 'stretch'},
              {'type': 'Y', 'height': 'stretch'},
            ],
            children: const [
              SizedBox(key: Key('a'), height: 10),
              SizedBox(key: Key('b'), height: 10),
            ],
            mainAxisAlignment: MainAxisAlignment.start,
          ),
        ],
      ),
    );
    expect(tester.getSize(find.byKey(const Key('a'))).height, 300);
    expect(tester.getSize(find.byKey(const Key('b'))).height, 300);
  });

  testWidgets('unbounded height: stretch degrades to auto, no Expanded',
      (tester) async {
    await tester.pumpWidget(
      host(
        maxHeight: null,
        child: [
          buildStretchableColumn(
            childMaps: const [
              {'type': 'X', 'height': 'stretch'},
            ],
            children: const [SizedBox(key: Key('s'), height: 10)],
            mainAxisAlignment: MainAxisAlignment.start,
          ),
        ],
      ),
    );
    // Unbounded height: stretch has nothing to fill, so the child keeps its
    // natural size (degrades to auto) and nothing throws.
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byKey(const Key('s'))).height, 10);
  });

  testWidgets('stretch child fills row band inside IntrinsicHeight',
      (tester) async {
    // IntrinsicHeight is how ColumnSet/Table give columns a bounded height;
    // the render object must report intrinsics (a LayoutBuilder would throw).
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // A tall sibling sets the row band to 200.
                  const SizedBox(width: 50, height: 200),
                  SizedBox(
                    width: 100,
                    child: buildStretchableColumn(
                      childMaps: const [
                        {'type': 'X'},
                        {'type': 'Y', 'height': 'stretch'},
                      ],
                      children: const [
                        SizedBox(key: Key('head'), height: 40),
                        SizedBox(key: Key('fill')),
                      ],
                      mainAxisAlignment: MainAxisAlignment.start,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    // Band is 200; the 40px header leaves 160 for the stretch child.
    expect(tester.getSize(find.byKey(const Key('fill'))).height, 160);
  });

  // Cross-axis positioning: a bounded box (300 wide, 200 tall) with a wide
  // non-stretch child (100) and a narrow stretch child (50). Width collapses to
  // the widest child (100) when not cross-stretching.
  Widget crossHost({
    required CrossAxisAlignment cross,
    TextDirection direction = TextDirection.ltr,
  }) {
    return MaterialApp(
      home: Directionality(
        textDirection: direction,
        child: Align(
          alignment: Alignment.topLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200, maxWidth: 300),
            child: buildStretchableColumn(
              childMaps: const [
                {'type': 'A'},
                {'type': 'B', 'height': 'stretch'},
              ],
              children: const [
                SizedBox(key: Key('wide'), width: 100, height: 20),
                SizedBox(key: Key('narrow'), width: 50),
              ],
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: cross,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('crossAxisAlignment.center centers the narrow child',
      (tester) async {
    await tester.pumpWidget(crossHost(cross: CrossAxisAlignment.center));
    // width collapses to 100; narrow (50) centered → dx = 25.
    expect(tester.getTopLeft(find.byKey(const Key('narrow'))).dx, 25);
  });

  testWidgets('crossAxisAlignment.end right-aligns the narrow child',
      (tester) async {
    await tester.pumpWidget(crossHost(cross: CrossAxisAlignment.end));
    // width 100; narrow (50) at end → dx = 50.
    expect(tester.getTopLeft(find.byKey(const Key('narrow'))).dx, 50);
  });

  testWidgets('crossAxisAlignment.stretch fills the bounded width',
      (tester) async {
    await tester.pumpWidget(crossHost(cross: CrossAxisAlignment.stretch));
    // cross-stretch + bounded width → children tightened to 300.
    expect(tester.getSize(find.byKey(const Key('narrow'))).width, 300);
  });

  testWidgets('RTL start aligns the narrow child to the right', (tester) async {
    await tester.pumpWidget(
      crossHost(cross: CrossAxisAlignment.start, direction: TextDirection.rtl),
    );
    // RTL start → narrow (50) sits at the right edge of width 100 → dx = 50.
    expect(tester.getTopLeft(find.byKey(const Key('narrow'))).dx, 50);
  });

  testWidgets('reports width intrinsics inside IntrinsicWidth', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: IntrinsicHeight(
              child: IntrinsicWidth(
                child: buildStretchableColumn(
                  childMaps: const [
                    {'type': 'A'},
                    {'type': 'B', 'height': 'stretch'},
                  ],
                  children: const [
                    SizedBox(key: Key('w'), width: 120, height: 20),
                    SizedBox(key: Key('s'), width: 60),
                  ],
                  mainAxisAlignment: MainAxisAlignment.start,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    // IntrinsicWidth shrink-wraps to the widest child (120).
    expect(tester.getSize(find.byKey(const Key('w'))).width, 120);
  });

  testWidgets('updateRenderObject applies changed cross alignment',
      (tester) async {
    await tester.pumpWidget(crossHost(cross: CrossAxisAlignment.start));
    expect(tester.getTopLeft(find.byKey(const Key('narrow'))).dx, 0);
    // Re-pump with a different alignment: the element reuses the render object,
    // exercising updateRenderObject's setters.
    await tester.pumpWidget(crossHost(cross: CrossAxisAlignment.end));
    expect(tester.getTopLeft(find.byKey(const Key('narrow'))).dx, 50);
  });
}
