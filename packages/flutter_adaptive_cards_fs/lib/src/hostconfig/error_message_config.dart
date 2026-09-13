/// HostConfig `inputs.errorMessage` section controlling validation error text.
class ErrorMessageConfig({
  /// Font size token for input validation error text.
  required final String size,

  /// Spacing token above/below validation error text.
  required final String spacing,

  /// Font weight token for validation error text.
  required final String weight,
}) {
  /// Creates error-message typography settings from explicit values.
  this;

  /// Parses `inputs.errorMessage` from HostConfig JSON.
  factory fromJson(Map<String, dynamic> json) {
    return ErrorMessageConfig(
      size: json['size']?.toString() ?? 'default',
      spacing: json['spacing']?.toString() ?? 'default',
      weight: json['weight']?.toString() ?? 'default',
    );
  }
}
