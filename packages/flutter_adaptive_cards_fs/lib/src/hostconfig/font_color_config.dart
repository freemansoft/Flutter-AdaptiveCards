import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/theme_color_fallbacks.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';

/// HostConfig foreground color pair (`default` and `subtle`) for a semantic
/// color name.
class FontColorConfig {
  /// Creates a foreground color pair from explicit values.
  FontColorConfig({
    required this.defaultColor,
    required this.subtleColor,
  });

  /// Parses a foreground color object from HostConfig JSON.
  factory FontColorConfig.fromJson(
    Map<String, dynamic> json, {
    FontColorConfig? defaults,
  }) {
    final base =
        defaults ??
        ThemeColorFallbacks.forParsing.foregroundColors.defaultColor;
    return FontColorConfig(
      defaultColor:
          parseHostConfigColor(json['default']) ??
          defaults?.defaultColor ??
          base.defaultColor,
      subtleColor:
          parseHostConfigColor(json['subtle']) ??
          defaults?.subtleColor ??
          base.subtleColor,
    );
  }

  /// Primary foreground color (`default`).
  final Color defaultColor;

  /// Subtle foreground color used when `isSubtle` is true (`subtle`).
  final Color subtleColor;
}
