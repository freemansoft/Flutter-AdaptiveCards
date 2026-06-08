import 'package:flutter_adaptive_cards_fs/src/hostconfig/foreground_colors_config.dart';

/// HostConfig `badgeStyles` entry defining background and foreground colors
/// for a single badge style variant.
class BadgeStyleConfig {
  /// Creates a badge style from explicit color configurations.
  BadgeStyleConfig({
    required this.backgroundColors,
    required this.foregroundColors,
  });

  /// Parses a badge style object from HostConfig JSON.
  factory BadgeStyleConfig.fromJson(
    Map<String, dynamic> json, {
    BadgeStyleConfig? defaults,
  }) {
    return BadgeStyleConfig(
      backgroundColors: json['backgroundColors'] is Map<String, dynamic>
          ? ForegroundColorsConfig.fromJson(
              json['backgroundColors'] as Map<String, dynamic>,
            )
          : defaults?.backgroundColors ?? ForegroundColorsConfig.fromJson({}),
      foregroundColors: json['foregroundColors'] is Map<String, dynamic>
          ? ForegroundColorsConfig.fromJson(
              json['foregroundColors'] as Map<String, dynamic>,
            )
          : defaults?.foregroundColors ?? ForegroundColorsConfig.fromJson({}),
    );
  }

  /// Background colors keyed by semantic color names.
  final ForegroundColorsConfig backgroundColors;

  /// Foreground (text/icon) colors keyed by semantic color names.
  final ForegroundColorsConfig foregroundColors;
}

/// HostConfig `badgeStyles` section mapping named badge variants to colors.
class BadgeStylesConfig {
  /// Creates badge style variants from explicit configurations.
  BadgeStylesConfig({
    required this.filled,
    required this.tint,
  });

  /// Parses `badgeStyles` from HostConfig JSON.
  factory BadgeStylesConfig.fromJson(Map<String, dynamic> json) {
    return BadgeStylesConfig(
      filled: BadgeStyleConfig.fromJson(
        json['filled'] ?? {},
        defaults: BadgeStyleConfig(
          backgroundColors: ForegroundColorsConfig.fromJson({}),
          foregroundColors: ForegroundColorsConfig.fromJson({}),
        ),
      ),
      tint: BadgeStyleConfig.fromJson(
        json['tint'] ?? {},
        defaults: BadgeStyleConfig(
          backgroundColors: ForegroundColorsConfig.fromJson({}),
          foregroundColors: ForegroundColorsConfig.fromJson({}),
        ),
      ),
    );
  }

  /// Solid-fill badge colors (`badgeStyles.filled`).
  final BadgeStyleConfig filled;

  /// Tinted badge colors (`badgeStyles.tint`).
  final BadgeStyleConfig tint;
}
