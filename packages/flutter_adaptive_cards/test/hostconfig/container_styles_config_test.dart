import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/src/hostconfig/container_styles_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ContainerStylesConfig', () {
    test('should deserialize correctly from JSON', () {
      final file = File('test/hostconfig/container_styles_config.json');
      final jsonString = file.readAsStringSync();
      final Map<String, dynamic> jsonMap =
          json.decode(jsonString) as Map<String, dynamic>;

      final config = ContainerStylesConfig.fromJson(jsonMap);

      expect(config.defaultStyle.backgroundColor, const Color(0xFFBBBBBB));
      expect(
        config.defaultStyle.foregroundColors.defaultColor.defaultColor,
        const Color(0xFF111111),
      );

      expect(config.emphasis.backgroundColor, const Color(0xFFCCCCCC));
      expect(
        config.emphasis.foregroundColors.accent.defaultColor,
        const Color(0xFF222222),
      );
    });

    test('should use default values when JSON is empty', () {
      final config = ContainerStylesConfig.fromJson({});

      expect(config.defaultStyle.backgroundColor, Colors.white);
      expect(config.emphasis.backgroundColor, const Color(0xFFF0F0F0));
    });
  });
}
