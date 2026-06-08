import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/fallback_configs.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';

/// HostConfig `progressSizes` section mapping size tokens to pixel dimensions
/// for ProgressBar and ProgressRing elements.
class ProgressSizesConfig {
  /// Creates progress size tokens from explicit pixel values.
  ProgressSizesConfig({
    required this.tiny,
    required this.small,
    required this.medium,
    required this.large,
    required this.extraLarge,
    required this.defaultSize,
  });

  /// Parses `progressSizes` from HostConfig JSON.
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

  /// Pixel size for the `tiny` progress size token.
  final int tiny;

  /// Pixel size for the `small` progress size token.
  final int small;

  /// Pixel size for the `medium` progress size token.
  final int medium;

  /// Pixel size for the `large` progress size token.
  final int large;

  /// Pixel size for the `extraLarge` progress size token.
  final int extraLarge;

  /// Pixel size for the `default` progress size token.
  final int defaultSize;

  /// Resolves a pixel size for ProgressBar or ProgressRing from a size token.
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

/// HostConfig `progressColors` section mapping semantic color names to progress
/// indicator fill colors.
class ProgressColorsConfig {
  /// Creates progress color mappings from explicit values.
  ProgressColorsConfig({
    required this.good,
    required this.warning,
    required this.attention,
    required this.accent,
    required this.defaultColor,
  });

  /// Parses `progressColors` from HostConfig JSON.
  factory ProgressColorsConfig.fromJson(Map<String, dynamic> json) {
    return ProgressColorsConfig(
      good: parseHostConfigColor(json['good']),
      warning: parseHostConfigColor(json['warning']),
      attention: parseHostConfigColor(json['attention']),
      accent: parseHostConfigColor(json['accent']),
      defaultColor: parseHostConfigColor(json['default']),
    );
  }

  /// Fill color for the `good` progress color token.
  final Color? good;

  /// Fill color for the `warning` progress color token.
  final Color? warning;

  /// Fill color for the `attention` progress color token.
  final Color? attention;

  /// Fill color for the `accent` progress color token.
  final Color? accent;

  /// Fill color for the `default` progress color token.
  final Color? defaultColor;

  /// Resolves a fill color for ProgressBar or ProgressRing from a color token.
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
