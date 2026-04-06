class ImageSetConfig {
  ImageSetConfig({
    required this.imageSizeSmall,
    required this.imageSizeMedium,
    required this.imageSizeLarge,
  });

  factory ImageSetConfig.fromJson(Map<String, dynamic> json) {
    return ImageSetConfig(
      imageSizeSmall: json['imageSizeSmall'] ?? 64,
      imageSizeMedium: json['imageSizeMedium'] ?? 64,
      imageSizeLarge: json['imageSizeLarge'] ?? 64,
    );
  }

  final int imageSizeSmall;
  final int imageSizeMedium;
  final int imageSizeLarge;

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
