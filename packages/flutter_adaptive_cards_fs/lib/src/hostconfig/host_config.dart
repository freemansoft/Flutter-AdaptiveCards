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

/// Top level configuration for Adaptive Cards
class HostConfig {
  /// Creates a HostConfig from explicit section values.
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

  /// Parses a HostConfig from JSON (all top-level HostConfig properties).
  factory HostConfig.fromJson(Map<String, dynamic> json) {
    return HostConfig(
      imageBaseUrl: json['imageBaseUrl']?.toString(),
      fontFamily: json['fontFamily']?.toString(),
      supportsInteractivity: json['supportsInteractivity'] as bool?,
      imageSet: (json['imageSet'] != null)
          ? ImageSetConfig.fromJson(json['imageSet'])
          : null,
      foregroundColors: (json['foregroundColors'] != null)
          ? ForegroundColorsConfig.fromJson(json['foregroundColors'])
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
          ? ContainerStylesConfig.fromJson(json['containerStyles'])
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

  /// Base URL prepended to relative image URLs (`imageBaseUrl`).
  final String? imageBaseUrl;

  /// Default font family for card text (`fontFamily`).
  final String? fontFamily;

  /// Whether interactive elements (inputs, actions) are enabled
  /// (`supportsInteractivity`).
  final bool? supportsInteractivity;

  /// Default pixel sizes for ImageSet element images (`imageSet`).
  final ImageSetConfig? imageSet;

  /// Semantic foreground color mappings (`foregroundColors`).
  final ForegroundColorsConfig? foregroundColors;

  /// Named text style defaults (`textStyles`).
  final TextStylesConfig? textStyles;

  /// Card-level rendering rules (`adaptiveCard`).
  final AdaptiveCardConfig? adaptiveCard;

  /// Action set layout and button chrome (`actions`).
  final ActionsConfig? actions;

  /// Named container background/foreground styles (`containerStyles`).
  final ContainerStylesConfig? containerStyles;

  /// FactSet typography and spacing (`factSet`).
  final FactSetConfig? factSet;

  /// Font size token mappings (`fontSizes`).
  final FontSizesConfig? fontSizes;

  /// Font weight token mappings (`fontWeights`).
  final FontWeightsConfig? fontWeights;

  /// Image element size token mappings (`imageSizes`).
  final ImageSizesConfig? imageSizes;

  /// Input label and error message styling (`inputs`).
  final InputsConfig? inputs;

  /// Media element defaults (`media`).
  final MediaConfig? media;

  /// Separator line appearance (`separator`).
  final SeparatorConfig? separator;

  /// Spacing token mappings (`spacing`).
  final SpacingsConfig? spacing;

  /// TextBlock heading defaults (`textBlock`).
  final TextBlockConfig? textBlock;

  /// Badge style color variants (`badgeStyles`).
  final BadgeStylesConfig? badgeStyles;

  /// Progress indicator size tokens (`progressSizes`).
  final ProgressSizesConfig? progressSizes;

  /// Progress indicator semantic colors (`progressColors`).
  final ProgressColorsConfig? progressColors;

  /// Chart default palette (`chartColors`).
  final ChartColorsConfig? chartColors;

  /// Chart layout dimensions and chrome (`chartsLayout`).
  final ChartsLayoutConfig? chartsLayout;
}
