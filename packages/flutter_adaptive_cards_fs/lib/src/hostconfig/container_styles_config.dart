import 'package:flutter_adaptive_cards_fs/src/hostconfig/container_style_config.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/theme_color_fallbacks.dart';

/// HostConfig `containerStyles` section mapping named container styles to
/// background and foreground colors.
class ContainerStylesConfig({
  /// Default container style (`containerStyles.default`).
  required final ContainerStyleConfig defaultStyle,

  /// Emphasis container style (`containerStyles.emphasis`).
  required final ContainerStyleConfig emphasis,

  /// Good (success) container style (`containerStyles.good`).
  final ContainerStyleConfig? good,

  /// Attention (error) container style (`containerStyles.attention`).
  final ContainerStyleConfig? attention,

  /// Warning container style (`containerStyles.warning`).
  final ContainerStyleConfig? warning,

  /// Accent container style (`containerStyles.accent`).
  final ContainerStyleConfig? accent,
}) {
  /// Creates container style variants from explicit configurations.
  this;

  /// Parses `containerStyles` from HostConfig JSON.
  factory fromJson(
    Map<String, dynamic> json, {
    ThemeColorFallbacks? colorDefaults,
  }) {
    final base = colorDefaults ?? ThemeColorFallbacks.forParsing;
    final defaults = base.containerStyles;
    return ContainerStylesConfig(
      defaultStyle: ContainerStyleConfig.fromJson(
        json['default'] ?? {},
        defaults: defaults.defaultStyle,
      ),
      emphasis: ContainerStyleConfig.fromJson(
        json['emphasis'] ?? {},
        defaults: defaults.emphasis,
      ),
      good: json['good'] == null
          ? null
          : ContainerStyleConfig.fromJson(
              json['good'],
              defaults: defaults.good,
            ),
      attention: json['attention'] == null
          ? null
          : ContainerStyleConfig.fromJson(
              json['attention'],
              defaults: defaults.attention,
            ),
      warning: json['warning'] == null
          ? null
          : ContainerStyleConfig.fromJson(
              json['warning'],
              defaults: defaults.warning,
            ),
      accent: json['accent'] == null
          ? null
          : ContainerStyleConfig.fromJson(
              json['accent'],
              defaults: defaults.accent,
            ),
    );
  }
}
