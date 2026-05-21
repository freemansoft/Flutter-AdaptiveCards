import 'package:flutter_adaptive_cards_fs/src/hostconfig/fallback_configs.dart';

class FontWeightsConfig {
  FontWeightsConfig({
    required this.lighter,
    required this.defaultWeight,
    required this.bolder,
  });

  /// This should from the theme but we don't have access to the theme
  factory FontWeightsConfig.fromJson(Map<String, dynamic> json) {
    final fallbackWeights = FallbackConfigs.fontWeightsConfig;
    return FontWeightsConfig(
      lighter: json['lighter'] as int? ?? fallbackWeights.lighter,
      defaultWeight: json['default'] as int? ?? fallbackWeights.defaultWeight,
      bolder: json['bolder'] as int? ?? fallbackWeights.bolder,
    );
  }

  final int lighter;
  final int defaultWeight;
  final int bolder;
}
