import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/charts_layout_config.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/font_sizes_config.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/font_weights_config.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/image_sizes_config.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/progress_config.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/spacings_config.dart';

/// Built-in HostConfig defaults used when JSON omits a section or property.
///
/// Color defaults are built from the ambient Flutter theme via
/// `ThemeColorFallbacks` and supplied per resolver at runtime.
class FallbackConfigs {
  /// Default `progressSizes` values for ProgressBar and ProgressRing.
  static final fallbackProgressSizesConfig = ProgressSizesConfig(
    tiny: 10,
    small: 20,
    medium: 30,
    large: 40,
    extraLarge: 50,
    defaultSize: 30,
  );

  /// Default `chartsLayout` values for Chart elements.
  static const ChartsLayoutConfig chartsLayoutConfig =
      ChartsLayoutConfig.defaults;

  /// Default `spacing` token values in logical pixels.
  static final SpacingsConfig spacingsConfig = SpacingsConfig(
    small: 4,
    medium: 8,
    large: 16,
    extraLarge: 32,
    defaultSpacing: 4,
    padding: 20,
  );

  /// Default `imageSizes` pixel dimensions for Image elements.
  static final imageSizesConfig = ImageSizesConfig(
    small: 32,
    medium: 64,
    large: 120,
  );

  /// Default `fontWeights` numeric values.
  static final FontWeightsConfig fontWeightsConfig = FontWeightsConfig(
    lighter: FontWeight.w200.value,
    defaultWeight: FontWeight.normal.value,
    bolder: FontWeight.bold.value,
  );

  /// Default `fontSizes` pixel values.
  static final FontSizesConfig fontSizesConfig = FontSizesConfig(
    small: 10,
    defaultSize: 12,
    medium: 14,
    large: 18,
    extraLarge: 22,
  );
}
