import 'package:flutter/material.dart';

class FontColorConfig {
  FontColorConfig({
    required this.defaultColor,
    required this.subtleColor,
  });

  factory FontColorConfig.fromJson(
    Map<String, dynamic> json, {
    FontColorConfig? defaults,
  }) {
    return FontColorConfig(
      defaultColor:
          _parseColor(json['default']) ??
          defaults?.defaultColor ??
          Colors.black,
      subtleColor:
          _parseColor(json['subtle']) ?? defaults?.subtleColor ?? Colors.grey,
    );
  }

  final Color defaultColor;
  final Color subtleColor;

  static Color? _parseColor(dynamic value) {
    if (value is! String) return null;
    if (!value.startsWith('#')) return null;

    // Handle #AARRGGBB or #RRGGBB
    String hex = value.substring(1);
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    if (hex.length != 8) return null;

    return Color(int.parse(hex, radix: 16));
  }
}
