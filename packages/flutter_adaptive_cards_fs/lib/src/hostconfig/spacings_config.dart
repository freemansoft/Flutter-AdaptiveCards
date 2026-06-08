import 'package:flutter_adaptive_cards_fs/src/hostconfig/fallback_configs.dart';

/// HostConfig `spacing` section mapping spacing tokens to pixel gaps.
class SpacingsConfig {
  /// Creates spacing tokens from explicit pixel values.
  SpacingsConfig({
    required this.small,
    required this.defaultSpacing,
    required this.medium,
    required this.large,
    required this.extraLarge,
    required this.padding,
  });

  /// Parses `spacing` from HostConfig JSON.
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

  /// Pixel gap for the `small` spacing token.
  final int small;

  /// Pixel gap for the `default` spacing token.
  final int defaultSpacing;

  /// Pixel gap for the `medium` spacing token.
  final int medium;

  /// Pixel gap for the `large` spacing token.
  final int large;

  /// Pixel gap for the `extraLarge` spacing token.
  final int extraLarge;

  /// Pixel padding applied inside containers (`spacing.padding`).
  final int padding;

  /// Resolves a pixel spacing value from a spacing token name.
  static double resolveSpacing(SpacingsConfig? config, String? spacing) {
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
