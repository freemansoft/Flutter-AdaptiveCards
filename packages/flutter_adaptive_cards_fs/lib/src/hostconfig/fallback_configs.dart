import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/charts_layout_config.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/choice_set_config.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/error_message_config.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/font_sizes_config.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/font_weights_config.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/host_widths_config.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/image_sizes_config.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/inputs_config.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/label_config.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/progress_config.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/spacings_config.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/text_input_config.dart';

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

  /// Default corner radius in logical pixels when HostConfig omits
  /// `cornerRadius`.
  ///
  /// `cornerRadius` backs the Microsoft Teams `roundedCorners` extension
  /// (beyond the base Adaptive Cards schema), wired on all five elements
  /// that support it — Container, ColumnSet, Column, Table, and Image. See
  /// https://learn.microsoft.com/en-us/microsoftteams/platform/task-modules-and-cards/cards/cards-format
  static const double cornerRadius = 8;

  /// Default responsive width breakpoints (Adaptive Cards spec defaults).
  static final HostWidthsConfig hostWidthsConfig = HostWidthsConfig(
    veryNarrowMax: 165,
    narrowMax: 350,
    standardMax: 768,
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

  /// Default `inputs` section values.
  ///
  /// **Non-standard:** the `text.revealPasswordEnabled` flag and the entire
  /// `choiceSet` section are custom extensions, not part of the official
  /// Adaptive Cards HostConfig schema.
  static final InputsConfig inputsConfig = InputsConfig(
    label: LabelConfig.fromJson(const <String, dynamic>{}),
    errorMessage: ErrorMessageConfig.fromJson(const <String, dynamic>{}),
    text: TextInputConfig(revealPasswordEnabled: true),
    choiceSet: ChoiceSetConfig(enableSearch: true),
  );
}
