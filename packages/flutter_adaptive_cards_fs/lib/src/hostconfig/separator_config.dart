class SeparatorConfig {
  SeparatorConfig({
    required this.lineThickness,
    required this.lineColor,
  });

  factory SeparatorConfig.fromJson(Map<String, dynamic> json) {
    return SeparatorConfig(
      lineThickness: json['lineThickness'] as int? ?? 1,
      lineColor: json['lineColor']?.toString() ?? '#B2000000',
    );
  }

  final int lineThickness;
  final String lineColor;
}
