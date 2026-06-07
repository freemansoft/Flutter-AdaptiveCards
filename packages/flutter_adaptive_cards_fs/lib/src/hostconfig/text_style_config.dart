/// Sets default properties for text of a given style
/// https://adaptivecards.io/explorer/TextStyleConfig.html
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
