class ErrorMessageConfig {
  ErrorMessageConfig({
    required this.size,
    required this.spacing,
    required this.weight,
  });

  factory ErrorMessageConfig.fromJson(Map<String, dynamic> json) {
    return ErrorMessageConfig(
      size: json['size']?.toString() ?? 'default',
      spacing: json['spacing']?.toString() ?? 'default',
      weight: json['weight']?.toString() ?? 'default',
    );
  }

  final String size;
  final String spacing;
  final String weight;
}
