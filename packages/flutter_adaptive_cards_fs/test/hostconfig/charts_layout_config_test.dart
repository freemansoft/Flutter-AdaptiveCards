import 'dart:convert';
import 'dart:io';

import 'package:flutter_adaptive_cards_fs/src/hostconfig/charts_layout_config.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/fallback_configs.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChartsLayoutConfig', () {
    test('deserializes from JSON fixture', () {
      final file = File('test/hostconfig/charts_layout_config.json');
      final jsonMap =
          json.decode(file.readAsStringSync()) as Map<String, dynamic>;
      final config = ChartsLayoutConfig.fromJson(jsonMap);

      expect(config.line.height, 300);
      expect(config.line.barWidth, 4);
      expect(config.bar.height, 260);
      expect(config.bar.barWidth, 20);
      expect(config.pie.sectionRadius, 90);
      expect(config.donut.centerSpaceRadius, 35);
    });

    test('resolveLineLayout falls back when config is null', () {
      final layout = ChartsLayoutConfig.resolveLineLayout(null);
      final fallback = FallbackConfigs.chartsLayoutConfig.line;
      expect(layout.height, fallback.height);
      expect(layout.borderColor, fallback.borderColor);
    });

    test('resolveBarLayout returns HostConfig values', () {
      final config = ChartsLayoutConfig.fromJson({
        'bar': {'height': 400, 'barWidth': 24, 'barsSpace': 8},
      });
      final layout = ChartsLayoutConfig.resolveBarLayout(config);
      expect(layout.height, 400);
      expect(layout.barWidth, 24);
      expect(layout.barsSpace, 8);
    });

    test('resolvePieLayout and resolveDonutLayout are independent', () {
      final config = ChartsLayoutConfig.fromJson({
        'pie': {'sectionRadius': 110},
        'donut': {'sectionRadius': 55},
      });
      expect(ChartsLayoutConfig.resolvePieLayout(config).sectionRadius, 110);
      expect(ChartsLayoutConfig.resolveDonutLayout(config).sectionRadius, 55);
    });
  });
}
