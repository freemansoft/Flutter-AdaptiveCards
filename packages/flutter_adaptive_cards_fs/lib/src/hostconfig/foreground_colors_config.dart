import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/font_color_config.dart';

/// HostConfig `foregroundColors` section mapping semantic color names to
/// default and subtle foreground colors.
class ForegroundColorsConfig {
  /// Creates foreground color mappings from explicit values.
  ForegroundColorsConfig({
    required this.defaultColor,
    required this.accent,
    required this.dark,
    required this.light,
    required this.good,
    required this.warning,
    required this.attention,
  });

  /// Parses `foregroundColors` from HostConfig JSON.
  factory ForegroundColorsConfig.fromJson(Map<String, dynamic> json) {
    return ForegroundColorsConfig(
      defaultColor: FontColorConfig.fromJson(
        json['default'] ?? {},
        defaults: FontColorConfig(
          defaultColor: const Color(0xFF000000),
          subtleColor: const Color(0xB2000000),
        ),
      ),
      accent: FontColorConfig.fromJson(
        json['accent'] ?? {},
        defaults: FontColorConfig(
          defaultColor: const Color(0xFF0000FF),
          subtleColor: const Color(0xB20000FF),
        ),
      ),
      dark: FontColorConfig.fromJson(
        json['dark'] ?? {},
        defaults: FontColorConfig(
          defaultColor: const Color(0xFF101010),
          subtleColor: const Color(0xB2101010),
        ),
      ),
      light: FontColorConfig.fromJson(
        json['light'] ?? {},
        defaults: FontColorConfig(
          defaultColor: const Color(0xFFFFFFFF),
          subtleColor: const Color(0xB2FFFFFF),
        ),
      ),
      good: FontColorConfig.fromJson(
        json['good'] ?? {},
        defaults: FontColorConfig(
          defaultColor: const Color(0xFF008000),
          subtleColor: const Color(0xB2008000),
        ),
      ),
      warning: FontColorConfig.fromJson(
        json['warning'] ?? {},
        defaults: FontColorConfig(
          defaultColor: const Color(0xFFFFD700),
          subtleColor: const Color(0xB2FFD700),
        ),
      ),
      attention: FontColorConfig.fromJson(
        json['attention'] ?? {},
        defaults: FontColorConfig(
          defaultColor: const Color(0xFF8B0000),
          subtleColor: const Color(0xB28B0000),
        ),
      ),
    );
  }

  /// Default foreground colors (`foregroundColors.default`).
  final FontColorConfig defaultColor;

  /// Accent foreground colors (`foregroundColors.accent`).
  final FontColorConfig accent;

  /// Dark foreground colors (`foregroundColors.dark`).
  final FontColorConfig dark;

  /// Light foreground colors (`foregroundColors.light`).
  final FontColorConfig light;

  /// Good (success) foreground colors (`foregroundColors.good`).
  final FontColorConfig good;

  /// Warning foreground colors (`foregroundColors.warning`).
  final FontColorConfig warning;

  /// Attention (error) foreground colors (`foregroundColors.attention`).
  final FontColorConfig attention;

  /// Resolves a [FontColorConfig] for the given semantic color name token.
  FontColorConfig fontColorConfig(String? colorName) {
    switch (colorName?.toLowerCase()) {
      case 'accent':
        return accent;
      case 'dark':
        return dark;
      case 'light':
        return light;
      case 'good':
        return good;
      case 'warning':
        return warning;
      case 'attention':
        return attention;
      case 'default':
      default:
        return defaultColor;
    }
  }
}
