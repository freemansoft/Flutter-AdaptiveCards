import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/container_styles_config.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/theme_color_fallbacks.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ContainerStylesConfig', () {
    test('should deserialize correctly from JSON', () {
      final file = File('test/hostconfig/container_styles_config.json');
      final jsonString = file.readAsStringSync();
      final Map<String, dynamic> jsonMap =
          json.decode(jsonString) as Map<String, dynamic>;

      final config = ContainerStylesConfig.fromJson(jsonMap);

      expect(config.defaultStyle.backgroundColor, const Color(0xFFBBBBBB));
      expect(
        config.defaultStyle.foregroundColors.defaultColor.defaultColor,
        const Color(0xFF111111),
      );

      expect(config.emphasis.backgroundColor, const Color(0xFFCCCCCC));
      expect(
        config.emphasis.foregroundColors.accent.defaultColor,
        const Color(0xFF222222),
      );
    });

    test('should use theme-derived defaults when JSON is empty', () {
      final theme = ThemeData.light();
      final colorDefaults = ThemeColorFallbacks(theme);
      final config = ContainerStylesConfig.fromJson(
        {},
        colorDefaults: colorDefaults,
      );

      expect(config.defaultStyle.backgroundColor, theme.colorScheme.surface);
      expect(
        config.emphasis.backgroundColor,
        theme.colorScheme.surfaceContainerHighest,
      );
    });

    test(
      'parses optional good/attention/warning/accent styles when present',
      () {
        final colorDefaults = ThemeColorFallbacks(ThemeData.light());
        final config = ContainerStylesConfig.fromJson(
          {
            'good': {'backgroundColor': '#FF00FF00'},
            'attention': {'backgroundColor': '#FFFF0000'},
            'warning': {'backgroundColor': '#FFFFFF00'},
            'accent': {'backgroundColor': '#FF0000FF'},
          },
          colorDefaults: colorDefaults,
        );

        expect(config.good?.backgroundColor, const Color(0xFF00FF00));
        expect(config.attention?.backgroundColor, const Color(0xFFFF0000));
        expect(config.warning?.backgroundColor, const Color(0xFFFFFF00));
        expect(config.accent?.backgroundColor, const Color(0xFF0000FF));
      },
    );

    test('leaves optional styles null when absent from JSON', () {
      final colorDefaults = ThemeColorFallbacks(ThemeData.light());
      final config = ContainerStylesConfig.fromJson(
        {},
        colorDefaults: colorDefaults,
      );

      expect(config.good, isNull);
      expect(config.attention, isNull);
      expect(config.warning, isNull);
      expect(config.accent, isNull);
    });
  });
}
