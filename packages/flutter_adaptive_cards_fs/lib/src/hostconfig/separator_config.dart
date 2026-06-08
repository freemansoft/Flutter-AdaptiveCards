/// HostConfig `separator` section controlling Separator element line
/// appearance.
class SeparatorConfig {
  /// Creates separator line settings from explicit values.
  SeparatorConfig({
    required this.lineThickness,
    required this.lineColor,
  });

  /// Parses `separator` from HostConfig JSON.
  factory SeparatorConfig.fromJson(Map<String, dynamic> json) {
    return SeparatorConfig(
      lineThickness: json['lineThickness'] as int? ?? 1,
      lineColor: json['lineColor']?.toString() ?? '#B2000000',
    );
  }

  /// Separator line thickness in pixels (`lineThickness`).
  final int lineThickness;

  /// Separator line color as a hex string (`lineColor`).
  final String lineColor;
}
