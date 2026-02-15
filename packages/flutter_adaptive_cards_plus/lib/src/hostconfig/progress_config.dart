import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_plus/src/hostconfig/fallback_configs.dart';

class ProgressSizesConfig {
  ProgressSizesConfig({
    required this.tiny,
    required this.small,
    required this.medium,
    required this.large,
    required this.extraLarge,
    required this.defaultSize,
  });

  factory ProgressSizesConfig.fromJson(Map<String, dynamic> json) {
    return ProgressSizesConfig(
      tiny: json['tiny'] as int? ?? 10,
      small: json['small'] as int? ?? 20,
      medium: json['medium'] as int? ?? 30,
      large: json['large'] as int? ?? 40,
      extraLarge: json['extraLarge'] as int? ?? 50,
      defaultSize: json['default'] as int? ?? 20,
    );
  }

  final int tiny;
  final int small;
  final int medium;
  final int large;
  final int extraLarge;
  final int defaultSize;

  /// Resolves the size for ProgressRing
  static double? resolveProgressSize(
    ProgressSizesConfig? config,
    String? size,
  ) {
    final String mySize = size?.toLowerCase() ?? 'default';

    if (config != null) {
      switch (mySize) {
        case 'tiny':
          return config.tiny.toDouble();
        case 'small':
          return config.small.toDouble();
        case 'medium':
          return config.medium.toDouble();
        case 'large':
          return config.large.toDouble();
        case 'extralarge':
          return config.extraLarge.toDouble();
        default:
          return config.defaultSize.toDouble();
      }
    } else {
      return resolveProgressSize(
        FallbackConfigs.fallbackProgressSizesConfig,
        size,
      );
    }
  }
}

class ProgressColorsConfig {
  ProgressColorsConfig({
    required this.good,
    required this.warning,
    required this.attention,
    required this.accent,
    required this.defaultColor,
  });

  /// use the FallbackConfigs if you need a default
  factory ProgressColorsConfig.fromJson(Map<String, dynamic> json) {
    return ProgressColorsConfig(
      good: _parseColor(json['good']),
      warning: _parseColor(json['warning']),
      attention: _parseColor(json['attention']),
      accent: _parseColor(json['accent']),
      defaultColor: _parseColor(json['default']),
    );
  }

  final Color? good;
  final Color? warning;
  final Color? attention;
  final Color? accent;
  final Color? defaultColor;

  static Color? _parseColor(dynamic value) {
    if (value is! String) return null;
    if (!value.startsWith('#')) return null;

    // Handle #AARRGGBB or #RRGGBB
    String hex = value.substring(1);
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    if (hex.length != 8) return null;

    return Color(int.parse(hex, radix: 16));
  }

  /// Resolves the color for ProgressBar and ProgressRing
  ///
  /// Typically one of:
  /// - good
  /// - warning
  /// - attention
  /// - accent
  static Color? resolveProgressColor({
    ProgressColorsConfig? config,
    required String? color,
  }) {
    // we don't return null here because we always have a fallback - is that the right approach
    final String myColor = color?.toLowerCase() ?? 'default';
    final myConfig = config ?? FallbackConfigs.fallbackProgressColorsConfig;

    switch (myColor) {
      case 'good':
        return myConfig.good;
      case 'warning':
        return myConfig.warning;
      case 'attention':
        return myConfig.attention;
      case 'accent':
        return myConfig.accent;
      default:
        return myConfig.defaultColor;
    }
  }
}
