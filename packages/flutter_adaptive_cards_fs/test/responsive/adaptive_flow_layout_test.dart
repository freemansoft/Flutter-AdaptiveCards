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
  });
}
