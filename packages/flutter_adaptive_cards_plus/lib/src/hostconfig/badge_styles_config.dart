import 'package:flutter_adaptive_cards_plus/src/hostconfig/foreground_colors_config.dart';

// a single badge style
class BadgeStyleConfig {
  BadgeStyleConfig({
    required this.backgroundColors,
    required this.foregroundColors,
  });

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

  final ForegroundColorsConfig backgroundColors;
  final ForegroundColorsConfig foregroundColors;
}

// the badge styles for all names
class BadgeStylesConfig {
  BadgeStylesConfig({
    required this.filled,
    required this.tint,
  });

  // the way this is written, both filled and tint are required
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

  final BadgeStyleConfig filled;
  final BadgeStyleConfig tint;
}
