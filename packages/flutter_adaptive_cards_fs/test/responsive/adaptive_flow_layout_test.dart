import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/host_config.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/theme_color_fallbacks.dart';
import 'package:flutter_adaptive_cards_fs/src/reference_resolver.dart';
import 'package:flutter_adaptive_cards_fs/src/responsive/adaptive_flow_layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final resolver = ReferenceResolver(
    hostConfigs: HostConfigs(),
    colorFallbacks: ThemeColorFallbacks(ThemeData.light()),
  );

  testWidgets('renders children inside a Wrap with resolved spacing/alignment',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdaptiveFlowLayout(
            layoutMap: const {
              'type': 'Layout.Flow',
              'columnSpacing': 'small',
              'rowSpacing': 'large',
              'horizontalItemsAlignment': 'center',
            },
            styleResolver: resolver,
            children: const [Text('a'), Text('b')],
          ),
        ),
      ),
    );

    expect(find.text('a'), findsOneWidget);
    expect(find.text('b'), findsOneWidget);
    final wrap = tester.widget<Wrap>(find.byType(Wrap));
    expect(wrap.alignment, WrapAlignment.center);
    expect(wrap.spacing, 4); // 'small' via FallbackConfigs.spacingsConfig
    expect(wrap.runSpacing, 16); // 'large' via FallbackConfigs.spacingsConfig
  });

  testWidgets('clamps item width to minItemWidth', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdaptiveFlowLayout(
            layoutMap: const {'type': 'Layout.Flow', 'minItemWidth': 200},
            styleResolver: resolver,
            children: const [Text('x')],
          ),
        ),
      ),
    );

    final constraints = tester
        .widget<ConstrainedBox>(
          find
              .ancestor(
                of: find.text('x'),
                matching: find.byType(ConstrainedBox),
              )
              .first,
        )
        .constraints;
    expect(constraints.minWidth, 200);
    // Content-fit items (min/max, no itemWidth) keep IntrinsicWidth so they
    // shrink to content instead of filling the row.
    expect(
      find.descendant(
        of: find.byType(AdaptiveFlowLayout),
        matching: find.byType(IntrinsicWidth),
      ),
      findsOneWidget,
    );
  });

  testWidgets('no sizing → each item is content-fit via IntrinsicWidth',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdaptiveFlowLayout(
            layoutMap: const {'type': 'Layout.Flow'},
            styleResolver: resolver,
            children: const [Text('a'), Text('b')],
          ),
        ),
      ),
    );

    // Both items are wrapped in IntrinsicWidth (content-fit), with no clamps.
    expect(find.byType(IntrinsicWidth), findsNWidgets(2));
    expect(
      find.descendant(
        of: find.byType(AdaptiveFlowLayout),
        matching: find.byType(ConstrainedBox),
      ),
      findsNothing,
    );
    expect(find.text('a'), findsOneWidget);
  });

  testWidgets('itemWidth gives each item a fixed-width SizedBox',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdaptiveFlowLayout(
            layoutMap: const {'type': 'Layout.Flow', 'itemWidth': '120px'},
            styleResolver: resolver,
            children: const [Text('x')],
          ),
        ),
      ),
    );

    final sized = tester.widget<SizedBox>(
      find
          .ancestor(of: find.text('x'), matching: find.byType(SizedBox))
          .first,
    );
    expect(sized.width, 120);
  });

  testWidgets('itemFit "Fill" does not throw and renders as Fit',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdaptiveFlowLayout(
            layoutMap: const {'type': 'Layout.Flow', 'itemFit': 'Fill'},
            styleResolver: resolver,
            children: const [Text('a'), Text('b')],
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('a'), findsOneWidget);
  });

  testWidgets('itemWidth is the safe escape for items without intrinsic width',
      (tester) async {
    // A nested Wrap has no intrinsic-width support, so the content-fit path
    // (IntrinsicWidth) cannot size it. Setting itemWidth switches to a SizedBox
    // (no IntrinsicWidth), which sizes such items without throwing.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdaptiveFlowLayout(
            layoutMap: const {'type': 'Layout.Flow', 'itemWidth': '100px'},
            styleResolver: resolver,
            children: const [
              Wrap(children: [Text('nested')]),
            ],
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(IntrinsicWidth), findsNothing);
    expect(find.text('nested'), findsOneWidget);
  });
}
