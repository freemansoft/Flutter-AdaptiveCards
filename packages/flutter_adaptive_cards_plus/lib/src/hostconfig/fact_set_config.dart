class FactSetTextConfig {
  FactSetTextConfig({
    required this.size,
    required this.weight,
    required this.color,
    required this.fontType,
    required this.isSubtle,
    required this.wrap,
    required this.maxWidth,
  });

  factory FactSetTextConfig.fromJson(
    Map<String, dynamic> json, {
    FactSetTextConfig? defaults,
  }) {
    return FactSetTextConfig(
      size: json['size']?.toString() ?? defaults?.size ?? 'default',
      weight: json['weight']?.toString() ?? defaults?.weight ?? 'default',
      color: json['color']?.toString() ?? defaults?.color ?? 'default',
      fontType: json['fontType']?.toString() ?? defaults?.fontType ?? 'default',
      isSubtle: json['isSubtle'] as bool? ?? defaults?.isSubtle ?? false,
      wrap: json['wrap'] as bool? ?? defaults?.wrap ?? true,
      maxWidth: json['maxWidth'] as int? ?? defaults?.maxWidth ?? 0,
    );
  }

  final String size;
  final String weight;
  final String color;
  final String fontType;
  final bool isSubtle;
  final bool wrap;
  final int maxWidth;
}

class FactSetConfig {
  FactSetConfig({
    required this.title,
    required this.value,
    required this.spacing,
  });

  factory FactSetConfig.fromJson(Map<String, dynamic> json) {
    return FactSetConfig(
      title: FactSetTextConfig.fromJson(
        json['title'] ?? {},
        defaults: FactSetTextConfig(
          weight: 'bolder',
          size: 'default',
          color: 'default',
          fontType: 'default',
          isSubtle: false,
          wrap: true,
          maxWidth: 150,
        ),
      ),
      value: FactSetTextConfig.fromJson(
        json['value'] ?? {},
        defaults: FactSetTextConfig(
          weight: 'default',
          size: 'default',
          color: 'default',
          fontType: 'default',
          isSubtle: false,
          wrap: true,
          maxWidth: 0,
        ),
      ),
      spacing: json['spacing'] as int? ?? 10,
    );
  }

  final FactSetTextConfig title;
  final FactSetTextConfig value;
  final int spacing;
}
