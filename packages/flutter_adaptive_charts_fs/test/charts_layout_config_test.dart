import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/charts_layout_config.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/host_config.dart';
import 'package:flutter_test/flutter_test.dart';

import 'utils/test_utils.dart';

void main() {
  testWidgets('custom chartsLayout height is applied to line chart', (
    tester,
  ) async {
    const key = ValueKey('line');
    final hostConfigs = HostConfigs(
      light: HostConfig(
        chartsLayout: ChartsLayoutConfig.fromJson({
          'line': {'height': 400},
        }),
      ),
      dark: HostConfig(
        chartsLayout: ChartsLayoutConfig.fromJson({
          'line': {'height': 400},
        }),
      ),
    );
    await tester.pumpWidget(
      getChartTestWidgetFromPath(
        path: 'v1.6/chart_line.json',
        key: key,
        hostConfigs: hostConfigs,
      ),
    );
    await tester.pumpAndSettle();

    final sizedBoxFinder = find.ancestor(
      of: find.byType(LineChart),
      matching: find.byType(SizedBox),
    );
    expect(sizedBoxFinder, findsOneWidget);
    final sizedBox = tester.widget<SizedBox>(sizedBoxFinder);
    expect(sizedBox.height, 400);
  });
}
