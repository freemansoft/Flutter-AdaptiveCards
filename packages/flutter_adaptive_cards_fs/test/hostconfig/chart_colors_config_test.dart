import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/chart_colors_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChartColorsConfig.fromJson', () {
    test('parses defaultPalette and defaultColor from hex strings', () {
      final config = ChartColorsConfig.fromJson({
        'defaultPalette': ['#112233', '#445566'],
        'defaultColor': '#778899',
      });

      expect(config.defaultPalette, const [
        Color(0xFF112233),
        Color(0xFF445566),
      ]);
      expect(config.defaultColor, const Color(0xFF778899));
    });

    test('defaults the color to the first palette entry when omitted', () {
      final config = ChartColorsConfig.fromJson({
        'defaultPalette': ['#112233'],
      });

      expect(config.defaultColor, const Color(0xFF112233));
    });

    test('falls back to an empty palette and blue when JSON is empty', () {
      final config = ChartColorsConfig.fromJson({});

      expect(config.defaultPalette, isEmpty);
      expect(config.defaultColor, Colors.blue);
    });
  });

  group('chartPaletteForSet', () {
    test('defaultPalette maps to the categorical palette', () {
      expect(
        chartPaletteForSet(ChartColorSetName.defaultPalette),
        kChartCategoricalPalette,
      );
    });
  });
}
