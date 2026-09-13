/// HostConfig `imageSet` section controlling default ImageSet image dimensions.
class ImageSetConfig({
  /// Pixel width/height for `small` ImageSet images (`imageSet.imageSizeSmall`).
  required final int imageSizeSmall,

  /// Pixel width/height for `medium` ImageSet images
  /// (`imageSet.imageSizeMedium`).
  required final int imageSizeMedium,

  /// Pixel width/height for `large` ImageSet images (`imageSet.imageSizeLarge`).
  required final int imageSizeLarge,
}) {
  /// Creates ImageSet size defaults from explicit pixel values.
  this;

  /// Parses `imageSet` from HostConfig JSON.
  factory fromJson(Map<String, dynamic> json) {
    return ImageSetConfig(
      imageSizeSmall: json['imageSizeSmall'] ?? 64,
      imageSizeMedium: json['imageSizeMedium'] ?? 64,
      imageSizeLarge: json['imageSizeLarge'] ?? 64,
    );
  }

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
