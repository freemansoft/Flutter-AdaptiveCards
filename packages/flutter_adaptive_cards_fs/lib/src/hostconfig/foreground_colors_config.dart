import 'package:flutter_adaptive_cards_fs/src/hostconfig/font_color_config.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/theme_color_fallbacks.dart';

/// HostConfig `foregroundColors` section mapping semantic color names to
/// default and subtle foreground colors.
class ForegroundColorsConfig({
  /// Default foreground colors (`foregroundColors.default`).
  required final FontColorConfig defaultColor,

  /// Accent foreground colors (`foregroundColors.accent`).
  required final FontColorConfig accent,

  /// Dark foreground colors (`foregroundColors.dark`).
  required final FontColorConfig dark,

  /// Light foreground colors (`foregroundColors.light`).
  required final FontColorConfig light,

  /// Good (success) foreground colors (`foregroundColors.good`).
  required final FontColorConfig good,

  /// Warning foreground colors (`foregroundColors.warning`).
  required final FontColorConfig warning,

  /// Attention (error) foreground colors (`foregroundColors.attention`).
  required final FontColorConfig attention,
}) {
  /// Creates foreground color mappings from explicit values.
  this;

  /// Parses `foregroundColors` from HostConfig JSON.
  factory fromJson(
    Map<String, dynamic> json, {
    ForegroundColorsConfig? defaults,
  }) {
    final base = defaults ?? ThemeColorFallbacks.forParsing.foregroundColors;
    return ForegroundColorsConfig(
      defaultColor: FontColorConfig.fromJson(
        json['default'] ?? {},
        defaults: base.defaultColor,
      ),
      accent: FontColorConfig.fromJson(
        json['accent'] ?? {},
        defaults: base.accent,
      ),
      dark: FontColorConfig.fromJson(
        json['dark'] ?? {},
        defaults: base.dark,
      ),
      light: FontColorConfig.fromJson(
        json['light'] ?? {},
        defaults: base.light,
      ),
      good: FontColorConfig.fromJson(
        json['good'] ?? {},
        defaults: base.good,
      ),
      warning: FontColorConfig.fromJson(
        json['warning'] ?? {},
        defaults: base.warning,
      ),
      attention: FontColorConfig.fromJson(
        json['attention'] ?? {},
        defaults: base.attention,
      ),
    );
  }

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
