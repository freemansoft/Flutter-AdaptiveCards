class TextStyleConfig {
  TextStyleConfig({
    required this.weight,
    required this.size,
    required this.color,
    required this.fontType,
    required this.isSubtle,
  });

  factory TextStyleConfig.fromJson(
    Map<String, dynamic> json, {
    TextStyleConfig? defaults,
  }) {
    return TextStyleConfig(
      weight: json['weight']?.toString() ?? defaults?.weight ?? 'default',
      size: json['size']?.toString() ?? defaults?.size ?? 'default',
      color: json['color']?.toString() ?? defaults?.color ?? 'default',
      fontType: json['fontType']?.toString() ?? defaults?.fontType ?? 'default',
      isSubtle: json['isSubtle'] as bool? ?? defaults?.isSubtle ?? false,
    );
  }

  final String weight;
  final String size;
  final String color;
  final String fontType;
  final bool isSubtle;
}

class TextStylesConfig {
  TextStylesConfig({
    required this.heading,
    required this.columnHeader,
  });

  factory TextStylesConfig.fromJson(Map<String, dynamic> json) {
    return TextStylesConfig(
      heading: TextStyleConfig.fromJson(
        json['heading'] ?? {},
        defaults: TextStyleConfig(
          weight: 'bolder',
          size: 'large',
          color: 'default',
          fontType: 'default',
          isSubtle: false,
        ),
      ),
      columnHeader: TextStyleConfig.fromJson(
        json['columnHeader'] ?? {},
        defaults: TextStyleConfig(
          weight: 'bolder',
          size: 'default',
          color: 'default',
          fontType: 'default',
          isSubtle: false,
        ),
      ),
    );
  }

  final TextStyleConfig heading;
  final TextStyleConfig columnHeader;
}
