import 'package:flutter_adaptive_cards_fs/src/hostconfig/foreground_colors_config.dart';

/// HostConfig `badgeStyles` entry defining background and foreground colors
/// for a single badge style variant.
class BadgeStyleConfig({
  /// Background colors keyed by semantic color names.
  required final ForegroundColorsConfig backgroundColors,

  /// Foreground (text/icon) colors keyed by semantic color names.
  required final ForegroundColorsConfig foregroundColors,
}) {
  /// Creates a badge style from explicit color configurations.
  this;

  /// Parses a badge style object from HostConfig JSON.
  factory fromJson(
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
}

/// HostConfig `badgeStyles` section mapping named badge variants to colors.
class BadgeStylesConfig({
  /// Solid-fill badge colors (`badgeStyles.filled`).
  required final BadgeStyleConfig filled,

  /// Tinted badge colors (`badgeStyles.tint`).
  required final BadgeStyleConfig tint,
}) {
  /// Creates badge style variants from explicit configurations.
  this;

  /// Parses `badgeStyles` from HostConfig JSON.
  factory fromJson(Map<String, dynamic> json) {
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
}
