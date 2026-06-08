/// HostConfig input label styling (`inputs.label.requiredInputs` or
/// `inputs.label.optionalInputs`).
class InputLabelConfig {
  /// Creates input label typography settings from explicit values.
  InputLabelConfig({
    required this.color,
    required this.isSubtle,
    required this.size,
    required this.suffix,
    required this.weight,
  });

  /// Parses an input label object from HostConfig JSON.
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

  /// Foreground color token for the input label.
  final String color;

  /// Whether the label uses the subtle color variant.
  final bool isSubtle;

  /// Font size token for the input label.
  final String size;

  /// Text appended after optional input labels (for example, "(optional)").
  final String suffix;

  /// Font weight token for the input label.
  final String weight;
}
