import 'package:flutter_adaptive_cards/src/hostconfig/foreground_colors_config.dart';

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
      backgroundColors: ForegroundColorsConfig.fromJson(
        json['backgroundColors'] ?? defaults?.backgroundColors ?? {},
      ),
      foregroundColors: ForegroundColorsConfig.fromJson(
        json['foregroundColors'] ?? defaults?.foregroundColors ?? {},
      ),
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
