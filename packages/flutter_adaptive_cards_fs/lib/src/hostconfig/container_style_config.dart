import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/foreground_colors_config.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';

class ContainerStyleConfig {
  ContainerStyleConfig({
    required this.backgroundColor,
    required this.foregroundColors,
  });

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

  final Color backgroundColor;
  final ForegroundColorsConfig foregroundColors;
}
