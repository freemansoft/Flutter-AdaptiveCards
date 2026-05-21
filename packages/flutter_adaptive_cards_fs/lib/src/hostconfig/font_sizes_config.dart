import 'package:flutter_adaptive_cards_fs/src/hostconfig/fallback_configs.dart';

class FontSizesConfig {
  FontSizesConfig({
    required this.small,
    required this.defaultSize,
    required this.medium,
    required this.large,
    required this.extraLarge,
  });

  /// This should from the theme but we don't have access to the theme
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

  final int small;
  final int defaultSize;
  final int medium;
  final int large;
  final int extraLarge;
}
