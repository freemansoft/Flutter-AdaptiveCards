import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';

/// Configuration for chart colors in Adaptive Cards Charts added in 1.6.
class ChartColorsConfig {
  const ChartColorsConfig({
    required this.defaultPalette,
    required this.defaultColor,
  });

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

  final List<Color> defaultPalette;
  final Color defaultColor;
}
