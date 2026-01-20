import 'package:flutter_adaptive_cards/src/hostconfig/fallback_configs.dart';

class ImageSizesConfig {
  ImageSizesConfig({
    required this.small,
    required this.medium,
    required this.large,
  });

  factory ImageSizesConfig.fromJson(Map<String, dynamic> json) {
    return ImageSizesConfig(
      small: json['small'] as int? ?? 80,
      medium: json['medium'] as int? ?? 120,
      large: json['large'] as int? ?? 180,
    );
  }

  final int small;
  final int medium;
  final int large;

  /// JSON Schema definition "ImageSize"
  /// Should standardize this or look up current zoom
  static int resolveImageSizes(
    ImageSizesConfig? config,
    String sizeDescription,
  ) {
    final myConfig = config ?? FallbackConfigs.imageSizesConfig;
    switch (sizeDescription.toLowerCase()) {
      case 'small':
        return myConfig.small;
      case 'medium':
        return myConfig.medium;
      case 'large':
        return myConfig.large;
      default:
        return myConfig.medium;
    }
  }
}
