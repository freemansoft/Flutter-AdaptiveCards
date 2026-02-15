import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_plus/src/hostconfig/font_color_config.dart';

class ForegroundColorsConfig {
  ForegroundColorsConfig({
    required this.defaultColor,
    required this.accent,
    required this.dark,
    required this.light,
    required this.good,
    required this.warning,
    required this.attention,
  });

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

  final FontColorConfig defaultColor;
  final FontColorConfig accent;
  final FontColorConfig dark;
  final FontColorConfig light;
  final FontColorConfig good;
  final FontColorConfig warning;
  final FontColorConfig attention;

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
