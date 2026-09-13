import 'package:flutter_adaptive_cards_fs/src/hostconfig/fallback_configs.dart';

/// HostConfig `fontWeights` section mapping weight tokens to numeric weights.
class FontWeightsConfig({
  /// Numeric weight for the `lighter` font weight token.
  required final int lighter,

  /// Numeric weight for the `default` font weight token.
  required final int defaultWeight,

  /// Numeric weight for the `bolder` font weight token.
  required final int bolder,
}) {
  /// Creates font weight tokens from explicit numeric values.
  this;

  /// Parses `fontWeights` from HostConfig JSON.
  factory fromJson(Map<String, dynamic> json) {
    final fallbackWeights = FallbackConfigs.fontWeightsConfig;
    return FontWeightsConfig(
      lighter: json['lighter'] as int? ?? fallbackWeights.lighter,
      defaultWeight: json['default'] as int? ?? fallbackWeights.defaultWeight,
      bolder: json['bolder'] as int? ?? fallbackWeights.bolder,
    );
  }
}
