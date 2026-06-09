import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/chart_colors_config.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/host_config.dart';
import 'package:flutter_adaptive_cards_fs/src/reference_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChartColorSets', () {
    test('parseChartColorSetName maps known names', () {
      expect(parseChartColorSetName('diverging'), ChartColorSetName.diverging);
      expect(parseChartColorSetName('Categorical'), ChartColorSetName.categorical);
      expect(parseChartColorSetName(null), ChartColorSetName.defaultPalette);
    });

    test('resolveChartColorToken resolves semantic and categorical tokens', () {
      expect(resolveChartColorToken('good'), const Color(0xFF107C10));
      expect(resolveChartColorToken('categoricalBlue'), const Color(0xFF0078D4));
      expect(resolveChartColorToken('sequential5'), const Color(0xFF2E75B6));
      expect(resolveChartColorToken('unknown'), isNull);
    });

    test('chartPaletteForSet returns non-empty palettes', () {
      expect(chartPaletteForSet(ChartColorSetName.diverging), isNotEmpty);
      expect(chartPaletteForSet(ChartColorSetName.sequential), hasLength(8));
    });
  });

  group('ReferenceResolver chart colors', () {
    test('resolveChartPalette uses colorSet when provided', () {
      final resolver = ReferenceResolver(
        hostConfigs: HostConfigs(light: const HostConfig()),
      );
      final diverging = resolver.resolveChartPalette(colorSet: 'diverging');
      expect(diverging, kChartDivergingPalette);

      final hostPalette = [Colors.pink, Colors.cyan];
      final withHost = ReferenceResolver(
        hostConfigs: HostConfigs(
          light: HostConfig(
            chartColors: ChartColorsConfig(
              defaultPalette: hostPalette,
              defaultColor: Colors.pink,
            ),
          ),
        ),
      );
      expect(withHost.resolveChartPalette(), hostPalette);
      expect(
        withHost.resolveChartPalette(colorSet: 'sequential'),
        kChartSequentialPalette,
      );
    });

    test('resolveChartColor resolves token before hex', () {
      final resolver = ReferenceResolver(
        hostConfigs: HostConfigs(light: const HostConfig()),
      );
      expect(
        resolver.resolveChartColor('divergingRed'),
        const Color(0xFFE81123),
      );
      expect(resolver.resolveChartColor('#FF00FF'), const Color(0xFFFF00FF));
    });
  });
}
