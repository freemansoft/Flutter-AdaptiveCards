/// HostConfig `separator` section controlling Separator element line
/// appearance.
class SeparatorConfig({
  /// Separator line thickness in pixels (`lineThickness`).
  required final int lineThickness,

  /// Separator line color as a hex string (`lineColor`).
  required final String lineColor,
}) {
  /// Creates separator line settings from explicit values.
  this;

  /// Parses `separator` from HostConfig JSON.
  factory fromJson(Map<String, dynamic> json) {
    return SeparatorConfig(
      lineThickness: json['lineThickness'] as int? ?? 1,
      lineColor: json['lineColor']?.toString() ?? '#B2000000',
    );
  }
}
