import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/badge_styles_config.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/fallback_configs.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/foreground_colors_config.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/theme_color_fallbacks.dart';
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

    test('spacingsConfig has correct default spacings', () {
      final config = FallbackConfigs.spacingsConfig;

      expect(config.small, 4);
      expect(config.medium, 8);
      expect(config.large, 16);
      expect(config.extraLarge, 32);
      expect(config.defaultSpacing, 4);
      expect(config.padding, 20);
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

    test('inputsConfig.choiceSet has correct defaults', () {
      final choiceSet = FallbackConfigs.inputsConfig.choiceSet;

      expect(choiceSet.enableSearch, isTrue);
      expect(choiceSet.requestFocusOnTap, isNull);
    });
  });

  group('ThemeColorFallbacks', () {
    test('light theme derives container surface from colorScheme', () {
      final theme = ThemeData.light();
      final fallbacks = ThemeColorFallbacks(theme);

      expect(
        fallbacks.containerStyles.defaultStyle.backgroundColor,
        theme.colorScheme.surface,
      );
      expect(
        fallbacks
            .containerStyles
            .defaultStyle
            .foregroundColors
            .defaultColor
            .defaultColor,
        theme.colorScheme.onSurface,
      );
    });

    test('dark theme derives container surface from colorScheme', () {
      final theme = ThemeData.dark();
      final fallbacks = ThemeColorFallbacks(theme);

      expect(
        fallbacks.containerStyles.defaultStyle.backgroundColor,
        theme.colorScheme.surface,
      );
      expect(
        fallbacks
            .containerStyles
            .defaultStyle
            .foregroundColors
            .defaultColor
            .defaultColor,
        theme.colorScheme.onSurface,
      );
    });

    test('badgeStyles exposes filled and tint variants', () {
      final fallbacks = ThemeColorFallbacks(ThemeData.light());

      expect(fallbacks.badgeStyles.filled, isA<BadgeStyleConfig>());
      expect(fallbacks.badgeStyles.tint, isA<BadgeStyleConfig>());
      expect(
        fallbacks.badgeStyles.filled.foregroundColors,
        isA<ForegroundColorsConfig>(),
      );
    });

    test('separator lineColor is a hex string', () {
      final fallbacks = ThemeColorFallbacks(ThemeData.light());

      expect(fallbacks.separator.lineThickness, 1);
      expect(fallbacks.separator.lineColor, startsWith('#'));
    });
  });
}
