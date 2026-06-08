import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/container_style_config.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/foreground_colors_config.dart';

/// HostConfig `containerStyles` section mapping named container styles to
/// background and foreground colors.
class ContainerStylesConfig {
  /// Creates container style variants from explicit configurations.
  ContainerStylesConfig({
    required this.defaultStyle,
    required this.emphasis,
    this.good,
    this.attention,
    this.warning,
    this.accent,
  });

  /// Parses `containerStyles` from HostConfig JSON.
  factory ContainerStylesConfig.fromJson(Map<String, dynamic> json) {
    return ContainerStylesConfig(
      defaultStyle: ContainerStyleConfig.fromJson(
        json['default'] ?? {},
        defaults: ContainerStyleConfig(
          backgroundColor: Colors.white,
          foregroundColors: ForegroundColorsConfig.fromJson({}),
        ),
      ),
      emphasis: ContainerStyleConfig.fromJson(
        json['emphasis'] ?? {},
        defaults: ContainerStyleConfig(
          backgroundColor: const Color(0xFFF0F0F0),
          foregroundColors: ForegroundColorsConfig.fromJson({}),
        ),
      ),
      good: json['good'] == null
          ? null
          : ContainerStyleConfig.fromJson(
              json['good'],
              defaults: ContainerStyleConfig(
                backgroundColor: const Color(0xFFCCFFCC), // Light green
                foregroundColors: ForegroundColorsConfig.fromJson({}),
              ),
            ),
      attention: json['attention'] == null
          ? null
          : ContainerStyleConfig.fromJson(
              json['attention'],
              defaults: ContainerStyleConfig(
                backgroundColor: const Color(0xFFFFCCCC), // Light red
                foregroundColors: ForegroundColorsConfig.fromJson({}),
              ),
            ),
      warning: json['warning'] == null
          ? null
          : ContainerStyleConfig.fromJson(
              json['warning'],
              defaults: ContainerStyleConfig(
                backgroundColor: const Color(0xFFFFE6CC), // Light orange
                foregroundColors: ForegroundColorsConfig.fromJson({}),
              ),
            ),
      accent: json['accent'] == null
          ? null
          : ContainerStyleConfig.fromJson(
              json['accent'],
              defaults: ContainerStyleConfig(
                backgroundColor: const Color(0xFFCCE6FF), // Light blue
                foregroundColors: ForegroundColorsConfig.fromJson({}),
              ),
            ),
    );
  }

  /// Default container style (`containerStyles.default`).
  final ContainerStyleConfig defaultStyle;

  /// Emphasis container style (`containerStyles.emphasis`).
  final ContainerStyleConfig emphasis;

  /// Good (success) container style (`containerStyles.good`).
  final ContainerStyleConfig? good;

  /// Attention (error) container style (`containerStyles.attention`).
  final ContainerStyleConfig? attention;

  /// Warning container style (`containerStyles.warning`).
  final ContainerStyleConfig? warning;

  /// Accent container style (`containerStyles.accent`).
  final ContainerStyleConfig? accent;
}
