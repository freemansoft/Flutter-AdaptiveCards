/// HostConfig `adaptiveCard` section controlling card-level rendering rules.
class AdaptiveCardConfig({
  /// Whether card authors may apply custom container styles on the root card.
  required final bool allowCustomStyle,
}) {
  /// Creates adaptive-card settings from explicit values.
  this;

  /// Parses `adaptiveCard` from HostConfig JSON.
  factory fromJson(Map<String, dynamic> json) {
    return AdaptiveCardConfig(
      allowCustomStyle: json['allowCustomStyle'] as bool? ?? true,
    );
  }
}
