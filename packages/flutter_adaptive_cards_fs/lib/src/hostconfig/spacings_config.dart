import 'package:flutter_adaptive_cards_fs/src/hostconfig/fallback_configs.dart';

/// HostConfig `spacing` section mapping spacing tokens to pixel gaps.
class SpacingsConfig({
  /// Pixel gap for the `small` spacing token.
  required final int small,

  /// Pixel gap for the `default` spacing token.
  required final int defaultSpacing,

  /// Pixel gap for the `medium` spacing token.
  required final int medium,

  /// Pixel gap for the `large` spacing token.
  required final int large,

  /// Pixel gap for the `extraLarge` spacing token.
  required final int extraLarge,

  /// Pixel padding applied inside containers (`spacing.padding`).
  required final int padding,
}) {
  /// Creates spacing tokens from explicit pixel values.
  this;

  /// Parses `spacing` from HostConfig JSON.
  factory fromJson(Map<String, dynamic> json) {
    return SpacingsConfig(
      small: json['small'] as int? ?? 3,
      defaultSpacing: json['default'] as int? ?? 8,
      medium: json['medium'] as int? ?? 20,
      large: json['large'] as int? ?? 30,
      extraLarge: json['extraLarge'] as int? ?? 40,
      padding: json['padding'] as int? ?? 20,
    );
  }

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
