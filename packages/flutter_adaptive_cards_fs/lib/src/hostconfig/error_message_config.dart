/// HostConfig `inputs.errorMessage` section controlling validation error text.
class ErrorMessageConfig {
  /// Creates error-message typography settings from explicit values.
  ErrorMessageConfig({
    required this.size,
    required this.spacing,
    required this.weight,
  });

  /// Parses `inputs.errorMessage` from HostConfig JSON.
  factory ErrorMessageConfig.fromJson(Map<String, dynamic> json) {
    return ErrorMessageConfig(
      size: json['size']?.toString() ?? 'default',
      spacing: json['spacing']?.toString() ?? 'default',
      weight: json['weight']?.toString() ?? 'default',
    );
  }

  /// Font size token for input validation error text.
  final String size;

  /// Spacing token above/below validation error text.
  final String spacing;

  /// Font weight token for validation error text.
  final String weight;
}
