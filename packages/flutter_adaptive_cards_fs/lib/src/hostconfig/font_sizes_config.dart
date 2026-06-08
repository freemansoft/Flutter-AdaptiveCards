import 'package:flutter_adaptive_cards_fs/src/hostconfig/fallback_configs.dart';

/// HostConfig `fontSizes` section mapping size tokens to pixel font sizes.
class FontSizesConfig {
  /// Creates font size tokens from explicit pixel values.
  FontSizesConfig({
    required this.small,
    required this.defaultSize,
    required this.medium,
    required this.large,
    required this.extraLarge,
  });

  /// Parses `fontSizes` from HostConfig JSON.
  factory FontSizesConfig.fromJson(Map<String, dynamic> json) {
    final fallbackSizes = FallbackConfigs.fontSizesConfig;
    return FontSizesConfig(
      small: json['small'] as int? ?? fallbackSizes.small,
      defaultSize: json['default'] as int? ?? fallbackSizes.defaultSize,
      medium: json['medium'] as int? ?? fallbackSizes.medium,
      large: json['large'] as int? ?? fallbackSizes.large,
      extraLarge: json['extraLarge'] as int? ?? fallbackSizes.extraLarge,
    );
  }

  /// Pixel size for the `small` font size token.
  final int small;

  /// Pixel size for the `default` font size token.
  final int defaultSize;

  /// Pixel size for the `medium` font size token.
  final int medium;

  /// Pixel size for the `large` font size token.
  final int large;

  /// Pixel size for the `extraLarge` font size token.
  final int extraLarge;
}
