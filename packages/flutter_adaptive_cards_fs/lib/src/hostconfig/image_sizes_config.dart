import 'package:flutter_adaptive_cards_fs/src/hostconfig/fallback_configs.dart';

/// HostConfig `imageSizes` section mapping size tokens to pixel dimensions
/// for Image elements.
class ImageSizesConfig {
  /// Creates image size tokens from explicit pixel values.
  ImageSizesConfig({
    required this.small,
    required this.medium,
    required this.large,
  });

  /// Parses `imageSizes` from HostConfig JSON.
  factory ImageSizesConfig.fromJson(Map<String, dynamic> json) {
    return ImageSizesConfig(
      small: json['small'] as int? ?? 80,
      medium: json['medium'] as int? ?? 120,
      large: json['large'] as int? ?? 180,
    );
  }

  /// Pixel dimension for the `small` image size token.
  final int small;

  /// Pixel dimension for the `medium` image size token.
  final int medium;

  /// Pixel dimension for the `large` image size token.
  final int large;

  /// Resolves a pixel dimension for the given image size token.
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
