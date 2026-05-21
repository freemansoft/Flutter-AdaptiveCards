class InputLabelConfig {
  InputLabelConfig({
    required this.color,
    required this.isSubtle,
    required this.size,
    required this.suffix,
    required this.weight,
  });

  factory InputLabelConfig.fromJson(
    Map<String, dynamic> json, {
    InputLabelConfig? defaults,
  }) {
    return InputLabelConfig(
      color: json['color']?.toString() ?? defaults?.color ?? 'default',
      isSubtle: json['isSubtle'] as bool? ?? defaults?.isSubtle ?? false,
      size: json['size']?.toString() ?? defaults?.size ?? 'default',
      suffix: json['suffix']?.toString() ?? defaults?.suffix ?? '',
      weight: json['weight']?.toString() ?? defaults?.weight ?? 'default',
    );
  }

  final String color;
  final bool isSubtle;
  final String size;
  final String suffix;
  final String weight;
}
