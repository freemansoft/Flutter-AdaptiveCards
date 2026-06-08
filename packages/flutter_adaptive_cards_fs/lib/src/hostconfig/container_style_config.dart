import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/foreground_colors_config.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';

/// HostConfig container style entry (`containerStyles.<name>`) defining
/// background and foreground colors for a container variant.
class ContainerStyleConfig {
  /// Creates a container style from explicit values.
  ContainerStyleConfig({
    required this.backgroundColor,
    required this.foregroundColors,
  });

  /// Parses a container style object from HostConfig JSON.
  factory ContainerStyleConfig.fromJson(
    Map<String, dynamic> json, {
    ContainerStyleConfig? defaults,
  }) {
    return ContainerStyleConfig(
      backgroundColor:
          parseHostConfigColor(json['backgroundColor']) ??
          defaults?.backgroundColor ??
          Colors.white,
      foregroundColors: ForegroundColorsConfig.fromJson(
        json['foregroundColors'] ?? {},
      ),
    );
  }

  /// Container background fill color (`backgroundColor`).
  final Color backgroundColor;

  /// Foreground colors for text and icons rendered on this container style.
  final ForegroundColorsConfig foregroundColors;
}
