import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/actions_config.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/adaptive_card_config.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/badge_styles_config.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/chart_colors_config.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/charts_layout_config.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/container_styles_config.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/fact_set_config.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/font_sizes_config.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/font_weights_config.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/foreground_colors_config.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/image_set_config.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/image_sizes_config.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/inputs_config.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/media_config.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/progress_config.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/separator_config.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/spacings_config.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/text_block_config.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/text_styles_config.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/theme_color_fallbacks.dart';

/// How RawAdaptiveCard selects between HostConfigs.light and HostConfigs.dark.
enum AdaptiveCardBrightnessMode {
  /// Follow Theme brightness (default).
  auto,

  /// Always use HostConfigs.light.
  light,

  /// Always use HostConfigs.dark.
  dark,
}

/// Light and dark HostConfig pair with a mutable [current] selection.
class HostConfigs {
  /// Creates a light/dark HostConfig pair; [current] starts as [light].
  HostConfigs({
    this.light = const HostConfig(),
    this.dark = const HostConfig(),
  }) {
    // should look at the teme
    current = light;
  }

  /// Active HostConfig used for rendering (set to [light] or [dark]).
  late HostConfig current;

  /// HostConfig for light theme rendering.
  final HostConfig light;

  /// HostConfig for dark theme rendering.
  final HostConfig dark;
}

/// Parsed Adaptive Cards HostConfig JSON that maps spec tokens to Flutter styling.
///
/// Scalar fields ([imageBaseUrl], [fontFamily], [supportsInteractivity]) apply
/// globally. Each nested section property mirrors a HostConfig JSON object and
/// supplies defaults for an element family (inputs, actions, charts, and so
/// on). Load via [HostConfig.fromJson] from host JSON, or compose sections in
/// code when building a config programmatically.
class HostConfig {
  /// Builds a HostConfig programmatically when you are not loading from JSON.
  const HostConfig({
    this.imageBaseUrl,
    this.fontFamily,
    this.supportsInteractivity,
    this.imageSet,
    this.foregroundColors,
    this.textStyles,
    this.adaptiveCard,
    this.actions,
    this.containerStyles,
    this.factSet,
    this.fontSizes,
    this.fontWeights,
    this.imageSizes,
    this.inputs,
    this.media,
    this.separator,
    this.spacing,
    this.textBlock,
    this.badgeStyles,
    this.progressSizes,
    this.progressColors,
    this.chartColors,
    this.chartsLayout,
  });

  /// Load HostConfig from card host JSON; optional [theme] supplies Material color fallbacks.
  factory HostConfig.fromJson(
    Map<String, dynamic> json, {
    ThemeData? theme,
  }) {
    final colorDefaults = ThemeColorFallbacks(theme ?? ThemeData());
    return HostConfig(
      imageBaseUrl: json['imageBaseUrl']?.toString(),
      fontFamily: json['fontFamily']?.toString(),
      supportsInteractivity: json['supportsInteractivity'] as bool?,
      imageSet: (json['imageSet'] != null)
          ? ImageSetConfig.fromJson(json['imageSet'])
          : null,
      foregroundColors: (json['foregroundColors'] != null)
          ? ForegroundColorsConfig.fromJson(
              json['foregroundColors'],
              defaults: colorDefaults.foregroundColors,
            )
          : null,
      textStyles: (json['textStyles'] != null)
          ? TextStylesConfig.fromJson(json['textStyles'])
          : null,
      adaptiveCard: (json['adaptiveCard'] != null)
          ? AdaptiveCardConfig.fromJson(json['adaptiveCard'])
          : null,
      actions: (json['actions'] != null)
          ? ActionsConfig.fromJson(json['actions'])
          : null,
      containerStyles: (json['containerStyles'] != null)
          ? ContainerStylesConfig.fromJson(
              json['containerStyles'],
              colorDefaults: colorDefaults,
            )
          : null,
      factSet: (json['factSet'] != null)
          ? FactSetConfig.fromJson(json['factSet'])
          : null,
      fontSizes: (json['fontSizes'] != null)
          ? FontSizesConfig.fromJson(json['fontSizes'])
          : null,
      fontWeights: (json['fontWeights'] != null)
          ? FontWeightsConfig.fromJson(json['fontWeights'])
          : null,
      imageSizes: (json['imageSizes'] != null)
          ? ImageSizesConfig.fromJson(json['imageSizes'])
          : null,
      inputs: (json['inputs'] != null)
          ? InputsConfig.fromJson(json['inputs'])
          : null,
      media: (json['media'] != null)
          ? MediaConfig.fromJson(json['media'])
          : null,
      separator: (json['separator'] != null)
          ? SeparatorConfig.fromJson(json['separator'])
          : null,
      spacing: (json['spacing'] != null)
          ? SpacingsConfig.fromJson(json['spacing'])
          : null,
      textBlock: (json['textBlock'] != null)
          ? TextBlockConfig.fromJson(json['textBlock'])
          : null,
      badgeStyles: (json['badgeStyles'] != null)
          ? BadgeStylesConfig.fromJson(json['badgeStyles'])
          : null,
      progressSizes: (json['progressSizes'] != null)
          ? ProgressSizesConfig.fromJson(json['progressSizes'])
          : null,
      progressColors: (json['progressColors'] != null)
          ? ProgressColorsConfig.fromJson(json['progressColors'])
          : null,
      chartColors: (json['chartColors'] != null)
          ? ChartColorsConfig.fromJson(json['chartColors'])
          : null,
      chartsLayout: (json['chartsLayout'] != null)
          ? ChartsLayoutConfig.fromJson(json['chartsLayout'])
          : null,
    );
  }

  /// Resolves relative image URLs in card JSON.
  final String? imageBaseUrl;

  /// Default font family for card text elements.
  final String? fontFamily;

  /// When false, inputs and actions are disabled for read-only card display.
  final bool? supportsInteractivity;

  /// ImageSet thumbnail sizing and layout defaults.
  final ImageSetConfig? imageSet;

  /// Semantic foreground colors for text and icons.
  final ForegroundColorsConfig? foregroundColors;

  /// Named text style presets for card typography.
  final TextStylesConfig? textStyles;

  /// Root AdaptiveCard container styling.
  final AdaptiveCardConfig? adaptiveCard;

  /// ActionSet layout and button chrome.
  final ActionsConfig? actions;

  /// Named container background and foreground styles.
  final ContainerStylesConfig? containerStyles;

  /// FactSet label and value typography and spacing.
  final FactSetConfig? factSet;

  /// Font size tokens referenced by card JSON.
  final FontSizesConfig? fontSizes;

  /// Font weight tokens referenced by card JSON.
  final FontWeightsConfig? fontWeights;

  /// Image element size tokens.
  final ImageSizesConfig? imageSizes;

  /// Input label, placeholder, and error styling.
  final InputsConfig? inputs;

  /// Media element chrome and playback defaults.
  final MediaConfig? media;

  /// Separator line weight and color.
  final SeparatorConfig? separator;

  /// Spacing tokens (`small`, `medium`, and so on).
  final SpacingsConfig? spacing;

  /// TextBlock heading and wrap defaults.
  final TextBlockConfig? textBlock;

  /// Badge color variants.
  final BadgeStylesConfig? badgeStyles;

  /// Progress ring and bar size tokens.
  final ProgressSizesConfig? progressSizes;

  /// Progress indicator semantic colors.
  final ProgressColorsConfig? progressColors;

  /// Default chart series palette.
  final ChartColorsConfig? chartColors;

  /// Chart dimensions and chrome; see [ChartsLayoutConfig].
  final ChartsLayoutConfig? chartsLayout;
}
