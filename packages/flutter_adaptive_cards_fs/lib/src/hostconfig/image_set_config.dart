/// HostConfig `imageSet` section controlling default ImageSet image dimensions.
class ImageSetConfig {
  /// Creates ImageSet size defaults from explicit pixel values.
  ImageSetConfig({
    required this.imageSizeSmall,
    required this.imageSizeMedium,
    required this.imageSizeLarge,
  });

  /// Parses `imageSet` from HostConfig JSON.
  factory ImageSetConfig.fromJson(Map<String, dynamic> json) {
    return ImageSetConfig(
      imageSizeSmall: json['imageSizeSmall'] ?? 64,
      imageSizeMedium: json['imageSizeMedium'] ?? 64,
      imageSizeLarge: json['imageSizeLarge'] ?? 64,
    );
  }

  /// Pixel width/height for `small` ImageSet images (`imageSet.imageSizeSmall`).
  final int imageSizeSmall;

  /// Pixel width/height for `medium` ImageSet images
  /// (`imageSet.imageSizeMedium`).
  final int imageSizeMedium;

  /// Pixel width/height for `large` ImageSet images (`imageSet.imageSizeLarge`).
  final int imageSizeLarge;

  /// Resolves a pixel size for the given ImageSet size token.
  int imageSize(String sizeDescription) {
    switch (sizeDescription.toLowerCase()) {
      case 'small':
        return imageSizeSmall;
      case 'medium':
        return imageSizeMedium;
      case 'large':
        return imageSizeLarge;
      default:
        return imageSizeMedium;
    }
  }
}
