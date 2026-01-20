class AdaptiveCardConfig {
  AdaptiveCardConfig({
    required this.allowCustomStyle,
  });

  factory AdaptiveCardConfig.fromJson(Map<String, dynamic> json) {
    return AdaptiveCardConfig(
      allowCustomStyle: json['allowCustomStyle'] as bool? ?? true,
    );
  }

  final bool allowCustomStyle;
}
