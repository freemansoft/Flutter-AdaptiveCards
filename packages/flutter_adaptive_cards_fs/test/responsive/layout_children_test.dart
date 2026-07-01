import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/host_config.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/theme_color_fallbacks.dart';
import 'package:flutter_adaptive_cards_fs/src/reference_resolver.dart';
import 'package:flutter_adaptive_cards_fs/src/responsive/adaptive_flow_layout.dart';
import 'package:flutter_adaptive_cards_fs/src/responsive/layout_children.dart';
import 'package:flutter_adaptive_cards_fs/src/responsive/width_bucket.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final resolver = ReferenceResolver(
    hostConfigs: HostConfigs(),
    colorFallbacks: ThemeColorFallbacks(ThemeData.light()),
  );

  Widget stackBuilder(List<Widget> children) => Column(children: children);

  testWidgets('returns AdaptiveFlowLayout when a Layout.Flow matches', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: buildLayoutChildren(
            layouts: const [
              {'type': 'Layout.Flow', 'targetWidth': 'atLeast:narrow'},
            ],
            bucket: WidthBucket.wide,
            styleResolver: resolver,
            children: const [Text('a')],
            stackBuilder: stackBuilder,
          ),
        ),
      ),
    );

    expect(find.byType(AdaptiveFlowLayout), findsOneWidget);
  });

  testWidgets('delegates to stackBuilder when no layout applies', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: buildLayoutChildren(
            layouts: null,
            bucket: WidthBucket.wide,
            styleResolver: resolver,
            children: const [Text('a')],
            stackBuilder: stackBuilder,
          ),
        ),
      ),
    );

    expect(find.byType(AdaptiveFlowLayout), findsNothing);
    expect(find.byType(Column), findsOneWidget);
  });
}
