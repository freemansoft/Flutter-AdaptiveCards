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

/// Named chart palette families from the Teams / Adaptive Cards chart color reference.
enum ChartColorSetName {
  /// HostConfig `chartColors.defaultPalette` or built-in categorical palette.
  defaultPalette,

  /// Categorical palette for distinct series.
  categorical,

  /// Sequential palette for ordered data.
  sequential,

  /// Diverging palette for data with a meaningful midpoint.
  diverging,
}

/// Parses a chart element's `colorSet` JSON string.
ChartColorSetName parseChartColorSetName(String? value) {
  switch (value?.toLowerCase()) {
    case 'categorical':
      return ChartColorSetName.categorical;
    case 'sequential':
      return ChartColorSetName.sequential;
    case 'diverging':
      return ChartColorSetName.diverging;
    default:
      return ChartColorSetName.defaultPalette;
  }
}

/// Built-in categorical palette aligned with Teams chart color tokens.
const List<Color> kChartCategoricalPalette = [
  Color(0xFF0078D4),
  Color(0xFF107C10),
  Color(0xFFFF8C00),
  Color(0xFFE81123),
  Color(0xFF5C2D91),
  Color(0xFF008272),
  Color(0xFF00188F),
  Color(0xFF737373),
];

/// Built-in sequential palette (sequential1–sequential8).
const List<Color> kChartSequentialPalette = [
  Color(0xFFDEEBF7),
  Color(0xFFBDD7EE),
  Color(0xFF9DC3E6),
  Color(0xFF6FA8DC),
  Color(0xFF2E75B6),
  Color(0xFF1F4E79),
  Color(0xFF16365C),
  Color(0xFF0F2439),
];

/// Built-in diverging palette (divergingBlue–divergingGray).
const List<Color> kChartDivergingPalette = [
  Color(0xFF0078D4),
  Color(0xFF5B9BD5),
  Color(0xFF9DC3E6),
  Color(0xFF00B0F0),
  Color(0xFF00B294),
  Color(0xFFFFC000),
  Color(0xFFF4B183),
  Color(0xFFE81123),
  Color(0xFF737373),
];

/// Semantic and categorical chart color tokens from the Teams chart reference.
const Map<String, Color> kChartSemanticColorTokens = {
  'good': Color(0xFF107C10),
  'warning': Color(0xFFFF8C00),
  'attention': Color(0xFFE81123),
  'accent': Color(0xFF0078D4),
  'neutral': Color(0xFF737373),
  'categoricalred': Color(0xFFE81123),
  'categoricalpurple': Color(0xFF5C2D91),
  'categoricallavender': Color(0xFFB4A0FF),
  'categoricalblue': Color(0xFF0078D4),
  'categoricallightblue': Color(0xFF00BCF2),
  'categoricalteal': Color(0xFF00B294),
  'categoricalgreen': Color(0xFF107C10),
  'categoricallime': Color(0xFFBAD80A),
  'categoricalmarigold': Color(0xFFFF8C00),
  'sequential1': Color(0xFFDEEBF7),
  'sequential2': Color(0xFFBDD7EE),
  'sequential3': Color(0xFF9DC3E6),
  'sequential4': Color(0xFF6FA8DC),
  'sequential5': Color(0xFF2E75B6),
  'sequential6': Color(0xFF1F4E79),
  'sequential7': Color(0xFF16365C),
  'sequential8': Color(0xFF0F2439),
  'divergingblue': Color(0xFF0078D4),
  'diverginglightblue': Color(0xFF5B9BD5),
  'divergingcyan': Color(0xFF9DC3E6),
  'divergingteal': Color(0xFF00B0F0),
  'divergingyellow': Color(0xFFFFC000),
  'divergingpeach': Color(0xFFF4B183),
  'diverginglightred': Color(0xFFF8696B),
  'divergingred': Color(0xFFE81123),
  'divergingmaroon': Color(0xFF8B0000),
  'diverginggray': Color(0xFF737373),
};

/// Returns the built-in palette for [name].
List<Color> chartPaletteForSet(ChartColorSetName name) {
  return switch (name) {
    ChartColorSetName.categorical => kChartCategoricalPalette,
    ChartColorSetName.sequential => kChartSequentialPalette,
    ChartColorSetName.diverging => kChartDivergingPalette,
    ChartColorSetName.defaultPalette => kChartCategoricalPalette,
  };
}

/// Resolves a Teams chart color token; returns null when [colorStr] is not a
/// known token.
Color? resolveChartColorToken(String? colorStr) {
  if (colorStr == null || colorStr.isEmpty) {
    return null;
  }
  final normalized = colorStr.replaceAll(RegExp(r'[\s_-]'), '').toLowerCase();
  return kChartSemanticColorTokens[normalized];
}
