import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_plus/src/hostconfig/badge_styles_config.dart';
import 'package:flutter_adaptive_cards_plus/src/hostconfig/container_styles_config.dart';
import 'package:flutter_adaptive_cards_plus/src/hostconfig/fallback_configs.dart';
import 'package:flutter_adaptive_cards_plus/src/hostconfig/foreground_colors_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FallbackConfigs', () {
    test('fallbackProgressSizesConfig has correct default values', () {
      final config = FallbackConfigs.fallbackProgressSizesConfig;

      expect(config.tiny, 10);
      expect(config.small, 20);
      expect(config.medium, 30);
      expect(config.large, 40);
      expect(config.extraLarge, 50);
      expect(config.defaultSize, 30);
    });

    test('fallbackProgressColorsConfig has correct default colors', () {
      final config = FallbackConfigs.fallbackProgressColorsConfig;

      expect(config.good, Colors.green);
      expect(config.warning, Colors.yellow);
      expect(config.attention, Colors.red);
      expect(config.accent, Colors.blue);
      expect(config.defaultColor, Colors.grey);
    });

    test('fallbackBadgeStylesConfig has filled and tint styles', () {
      final config = FallbackConfigs.fallbackBadgeStylesConfig;

      expect(config.filled, isA<BadgeStyleConfig>());
      expect(config.tint, isA<BadgeStyleConfig>());

      // Verify filled style has foreground and background colors
      expect(config.filled.foregroundColors, isA<ForegroundColorsConfig>());
      expect(config.filled.backgroundColors, isA<ForegroundColorsConfig>());

      // Verify tint style has foreground and background colors
      expect(config.tint.foregroundColors, isA<ForegroundColorsConfig>());
      expect(config.tint.backgroundColors, isA<ForegroundColorsConfig>());
    });

    test('spacingsConfig has correct default spacings', () {
      final config = FallbackConfigs.spacingsConfig;

      expect(config.small, 4);
      expect(config.medium, 8);
      expect(config.large, 16);
      expect(config.extraLarge, 32);
      expect(config.defaultSpacing, 4);
      expect(config.padding, 20);
    });

    test('containerStylesConfig has default and emphasis styles', () {
      final config = FallbackConfigs.containerStylesConfig;

      expect(config.defaultStyle, isA<ContainerStyleConfig>());
      expect(config.emphasis, isA<ContainerStyleConfig>());

      expect(config.defaultStyle.backgroundColor, Colors.white);
      expect(config.emphasis.backgroundColor, Colors.grey);

      expect(
        config.defaultStyle.foregroundColors,
        isA<ForegroundColorsConfig>(),
      );
      expect(config.emphasis.foregroundColors, isA<ForegroundColorsConfig>());
    });

    test('imageSizesConfig has correct sizes', () {
      final config = FallbackConfigs.imageSizesConfig;

      expect(config.small, 32);
      expect(config.medium, 64);
      expect(config.large, 120);
    });

    test('fontWeightsConfig has correct weights', () {
      final config = FallbackConfigs.fontWeightsConfig;

      expect(config.lighter, FontWeight.w200.value);
      expect(config.defaultWeight, FontWeight.normal.value);
      expect(config.bolder, FontWeight.bold.value);
    });

    test('fontSizesConfig has correct sizes', () {
      final config = FallbackConfigs.fontSizesConfig;

      expect(config.small, 10);
      expect(config.defaultSize, 12);
      expect(config.medium, 14);
      expect(config.large, 18);
      expect(config.extraLarge, 22);
    });

    test('separatorConfig has correct default values', () {
      final config = FallbackConfigs.separatorConfig;

      expect(config.lineThickness, 1);
      expect(config.lineColor, isA<String>());
      // Line color should be a hex string
      expect(config.lineColor.length, greaterThan(0));
    });
  });
}
