import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';

/// HostConfig `chartColors` section controlling default palette for Chart
/// elements (Adaptive Cards 1.6+).
class ChartColorsConfig {
  /// Creates chart color settings from explicit values.
  const ChartColorsConfig({
    required this.defaultPalette,
    required this.defaultColor,
  });

  /// Parses `chartColors` from HostConfig JSON.
  factory ChartColorsConfig.fromJson(Map<String, dynamic> json) {
    final List<dynamic>? paletteJson = json['defaultPalette'] as List<dynamic>?;
    final List<Color> palette =
        paletteJson
            ?.map((e) => parseHexColor(e.toString()) ?? Colors.blue)
            .toList() ??
        [];

    return ChartColorsConfig(
      defaultPalette: palette,
      defaultColor:
          parseHexColor(json['defaultColor']?.toString()) ??
          (palette.isNotEmpty ? palette.first : Colors.blue),
    );
  }

  /// Ordered series colors cycled when a chart has more data than palette
  /// entries (`chartColors.defaultPalette`).
  final List<Color> defaultPalette;

  /// Fallback color when a series index has no palette entry
  /// (`chartColors.defaultColor`).
  final Color defaultColor;
}
