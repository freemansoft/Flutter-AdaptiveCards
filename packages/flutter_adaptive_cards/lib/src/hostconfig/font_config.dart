class FontSizesConfig {
  FontSizesConfig({
    required this.small,
    required this.defaultSize,
    required this.medium,
    required this.large,
    required this.extraLarge,
  });

  factory FontSizesConfig.fromJson(Map<String, dynamic> json) {
    return FontSizesConfig(
      small: json['small'] as int? ?? 10,
      defaultSize: json['default'] as int? ?? 12,
      medium: json['medium'] as int? ?? 14,
      large: json['large'] as int? ?? 17,
      extraLarge: json['extraLarge'] as int? ?? 20,
    );
  }

  final int small;
  final int defaultSize;
  final int medium;
  final int large;
  final int extraLarge;
}

class FontWeightsConfig {
  FontWeightsConfig({
    required this.lighter,
    required this.defaultWeight,
    required this.bolder,
  });

  factory FontWeightsConfig.fromJson(Map<String, dynamic> json) {
    return FontWeightsConfig(
      lighter: json['lighter'] as int? ?? 200,
      defaultWeight: json['default'] as int? ?? 400,
      bolder: json['bolder'] as int? ?? 800,
    );
  }

  final int lighter;
  final int defaultWeight;
  final int bolder;
}
