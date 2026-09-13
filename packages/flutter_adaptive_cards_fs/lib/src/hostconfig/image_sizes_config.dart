import 'package:flutter_adaptive_cards_fs/src/hostconfig/fallback_configs.dart';

/// HostConfig `imageSizes` section mapping size tokens to pixel dimensions
/// for Image elements.
class ImageSizesConfig({
  /// Pixel dimension for the `small` image size token.
  required final int small,

  /// Pixel dimension for the `medium` image size token.
  required final int medium,

  /// Pixel dimension for the `large` image size token.
  required final int large,
}) {
  /// Creates image size tokens from explicit pixel values.
  this;

  /// Parses `imageSizes` from HostConfig JSON.
  factory fromJson(Map<String, dynamic> json) {
    return ImageSizesConfig(
      small: json['small'] as int? ?? 80,
      medium: json['medium'] as int? ?? 120,
      large: json['large'] as int? ?? 180,
    );
  }

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
