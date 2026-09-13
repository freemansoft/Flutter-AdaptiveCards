/// HostConfig input label styling (`inputs.label.requiredInputs` or
/// `inputs.label.optionalInputs`).
class InputLabelConfig({
  /// Foreground color token for the input label.
  required final String color,

  /// Whether the label uses the subtle color variant.
  required final bool isSubtle,

  /// Font size token for the input label.
  required final String size,

  /// Text appended after optional input labels (for example, "(optional)").
  required final String suffix,

  /// Font weight token for the input label.
  required final String weight,
}) {
  /// Creates input label typography settings from explicit values.
  this;

  /// Parses an input label object from HostConfig JSON.
  factory fromJson(
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
}
