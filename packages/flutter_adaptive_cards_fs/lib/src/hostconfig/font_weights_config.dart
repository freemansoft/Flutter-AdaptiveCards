import 'package:flutter_adaptive_cards_fs/src/hostconfig/fallback_configs.dart';

/// HostConfig `fontWeights` section mapping weight tokens to numeric weights.
class FontWeightsConfig {
  /// Creates font weight tokens from explicit numeric values.
  FontWeightsConfig({
    required this.lighter,
    required this.defaultWeight,
    required this.bolder,
  });

  /// Parses `fontWeights` from HostConfig JSON.
  factory FontWeightsConfig.fromJson(Map<String, dynamic> json) {
    final fallbackWeights = FallbackConfigs.fontWeightsConfig;
    return FontWeightsConfig(
      lighter: json['lighter'] as int? ?? fallbackWeights.lighter,
      defaultWeight: json['default'] as int? ?? fallbackWeights.defaultWeight,
      bolder: json['bolder'] as int? ?? fallbackWeights.bolder,
    );
  }

  /// Numeric weight for the `lighter` font weight token.
  final int lighter;

  /// Numeric weight for the `default` font weight token.
  final int defaultWeight;

  /// Numeric weight for the `bolder` font weight token.
  final int bolder;
}
