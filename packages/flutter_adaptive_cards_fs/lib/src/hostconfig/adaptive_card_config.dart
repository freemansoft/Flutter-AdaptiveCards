/// HostConfig `adaptiveCard` section controlling card-level rendering rules.
class AdaptiveCardConfig {
  /// Creates adaptive-card settings from explicit values.
  AdaptiveCardConfig({
    required this.allowCustomStyle,
  });

  /// Parses `adaptiveCard` from HostConfig JSON.
  factory AdaptiveCardConfig.fromJson(Map<String, dynamic> json) {
    return AdaptiveCardConfig(
      allowCustomStyle: json['allowCustomStyle'] as bool? ?? true,
    );
  }

  /// Whether card authors may apply custom container styles on the root card.
  final bool allowCustomStyle;
}
