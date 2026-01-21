import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/src/hostconfig/font_color_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FontColorConfig should deserialize correctly from JSON', () {
    final file = File('test/hostconfig/font_color_config.json');
    final jsonString = file.readAsStringSync();
    final Map<String, dynamic> jsonMap =
        json.decode(jsonString) as Map<String, dynamic>;

    final config = FontColorConfig.fromJson(jsonMap);

    expect(config.defaultColor, const Color(0xFF123456));
    expect(config.subtleColor, const Color(0xB2654321));
  });

  test('FontColorConfig should use default values when JSON is empty', () {
    final config = FontColorConfig.fromJson({});

    expect(config.defaultColor, Colors.black);
    expect(config.subtleColor, Colors.grey);
  });
}
