import 'package:flutter_adaptive_cards/src/hostconfig/fallback_configs.dart';

class MediaConfig {
  MediaConfig({
    required this.defaultPoster,
    required this.playButton,
    required this.allowInlinePlayback,
  });

  factory MediaConfig.fromJson(Map<String, dynamic> json) {
    return MediaConfig(
      defaultPoster: json['defaultPoster']?.toString() ?? '',
      playButton: json['playButton']?.toString() ?? '',
      allowInlinePlayback: json['allowInlinePlayback'] as bool? ?? true,
    );
  }

  final String defaultPoster;
  final String playButton;
  final bool allowInlinePlayback;
}

class SeparatorConfig {
  SeparatorConfig({
    required this.lineThickness,
    required this.lineColor,
  });

  factory SeparatorConfig.fromJson(Map<String, dynamic> json) {
    return SeparatorConfig(
      lineThickness: json['lineThickness'] as int? ?? 1,
      lineColor: json['lineColor']?.toString() ?? '#B2000000',
    );
  }

  final int lineThickness;
  final String lineColor;
}

class SpacingsConfig {
  SpacingsConfig({
    required this.small,
    required this.defaultSpacing,
    required this.medium,
    required this.large,
    required this.extraLarge,
    required this.padding,
  });

  factory SpacingsConfig.fromJson(Map<String, dynamic> json) {
    return SpacingsConfig(
      small: json['small'] as int? ?? 3,
      defaultSpacing: json['default'] as int? ?? 8,
      medium: json['medium'] as int? ?? 20,
      large: json['large'] as int? ?? 30,
      extraLarge: json['extraLarge'] as int? ?? 40,
      padding: json['padding'] as int? ?? 20,
    );
  }

  final int small;
  final int defaultSpacing;
  final int medium;
  final int large;
  final int extraLarge;
  final int padding;

  /// JSON Schema definition "Spacing"
  /// Values include
  /// - default
  /// - none
  /// - small
  /// - medium
  /// - large
  /// - extraLarge
  ///
  static double? resolveSpacing(SpacingsConfig? config, String? spacing) {
    final String mySpacing = spacing ?? 'default';
    // special case created by someone
    if (mySpacing == 'none') return 0;

    final myConfig = config ?? FallbackConfigs.spacingsConfig;

    switch (mySpacing) {
      case 'small':
        return myConfig.small.toDouble();
      case 'medium':
        return myConfig.medium.toDouble();
      case 'large':
        return myConfig.large.toDouble();
      case 'extraLarge':
        return myConfig.extraLarge.toDouble();
      case 'padding':
        return myConfig.padding.toDouble();
      default:
        return myConfig.defaultSpacing.toDouble();
    }
  }
}

class TextBlockConfig {
  TextBlockConfig({
    required this.headingLevel,
  });

  factory TextBlockConfig.fromJson(Map<String, dynamic> json) {
    return TextBlockConfig(
      headingLevel: json['headingLevel'] as int? ?? 2,
    );
  }

  final int headingLevel;
}
