import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';

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
          parseHostConfigColor(json['default']) ??
          defaults?.defaultColor ??
          Colors.black,
      subtleColor:
          parseHostConfigColor(json['subtle']) ??
          defaults?.subtleColor ??
          Colors.grey,
    );
  }

  final Color defaultColor;
  final Color subtleColor;
}
