import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/foreground_colors_config.dart';

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
          _parseColor(json['backgroundColor']) ??
          defaults?.backgroundColor ??
          Colors.white,
      foregroundColors: ForegroundColorsConfig.fromJson(
        json['foregroundColors'] ?? {},
      ),
    );
  }

  final Color backgroundColor;
  final ForegroundColorsConfig foregroundColors;

  static Color? _parseColor(dynamic value) {
    if (value is! String) return null;
    if (!value.startsWith('#')) return null;

    String hex = value.substring(1);
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    if (hex.length != 8) return null;

    return Color(int.parse(hex, radix: 16));
  }
}
