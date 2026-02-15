import 'package:flutter_adaptive_cards_plus/src/hostconfig/actions_config.dart';
import 'package:flutter_adaptive_cards_plus/src/hostconfig/adaptive_card_config.dart';
import 'package:flutter_adaptive_cards_plus/src/hostconfig/badge_styles_config.dart';
import 'package:flutter_adaptive_cards_plus/src/hostconfig/container_styles_config.dart';
import 'package:flutter_adaptive_cards_plus/src/hostconfig/fact_set_config.dart';
import 'package:flutter_adaptive_cards_plus/src/hostconfig/font_config.dart';
import 'package:flutter_adaptive_cards_plus/src/hostconfig/foreground_colors_config.dart';
import 'package:flutter_adaptive_cards_plus/src/hostconfig/image_set_config.dart';
import 'package:flutter_adaptive_cards_plus/src/hostconfig/image_sizes_config.dart';
import 'package:flutter_adaptive_cards_plus/src/hostconfig/inputs_config.dart';
import 'package:flutter_adaptive_cards_plus/src/hostconfig/miscellaneous_configs.dart';
import 'package:flutter_adaptive_cards_plus/src/hostconfig/progress_config.dart';
import 'package:flutter_adaptive_cards_plus/src/hostconfig/text_style_config.dart';

class HostConfigs {
  HostConfigs({
    this.light = const HostConfig(),
    this.dark = const HostConfig(),
  }) {
    // should look at the teme
    current = light;
  }

  /// can set this to light or dark o something else
  late HostConfig current;

  /// for the light theme
  final HostConfig light;

  /// for the dark theme
  final HostConfig dark;
}

/// Top level configuration for Adaptive Cards
class HostConfig {
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
  });

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
    );
  }

  final String? imageBaseUrl;
  final String? fontFamily;
  final bool? supportsInteractivity;
  final ImageSetConfig? imageSet;
  final ForegroundColorsConfig? foregroundColors;
  final TextStylesConfig? textStyles;
  final AdaptiveCardConfig? adaptiveCard;
  final ActionsConfig? actions;
  final ContainerStylesConfig? containerStyles;
  final FactSetConfig? factSet;
  final FontSizesConfig? fontSizes;
  final FontWeightsConfig? fontWeights;
  final ImageSizesConfig? imageSizes;
  final InputsConfig? inputs;
  final MediaConfig? media;
  final SeparatorConfig? separator;
  final SpacingsConfig? spacing;
  final TextBlockConfig? textBlock;
  final BadgeStylesConfig? badgeStyles;
  final ProgressSizesConfig? progressSizes;
  final ProgressColorsConfig? progressColors;
}
