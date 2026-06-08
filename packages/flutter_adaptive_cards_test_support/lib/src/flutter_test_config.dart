import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_adaptive_cards_test_support/src/http_overrides.dart';
import 'package:flutter_test/flutter_test.dart';

/// Loads Roboto fonts used by HostConfig-driven golden tests.
Future<void> loadAdaptiveCardsTestFonts({
  String fontsRoot = 'assets/fonts/Roboto',
}) async {
  final fontNames = [
    'Roboto-Regular.ttf',
    'Roboto-Bold.ttf',
    'Roboto-Light.ttf',
    'Roboto-Medium.ttf',
    'Roboto-Thin.ttf',
    'RobotoMono-Regular.ttf',
    'RobotoMono-Bold.ttf',
    'RobotoMono-Light.ttf',
    'RobotoMono-Medium.ttf',
    'RobotoMono-Thin.ttf',
  ];

  final fontLoader = FontLoader('Roboto');
  for (final name in fontNames) {
    final bytes = await File('$fontsRoot/$name').readAsBytes();
    fontLoader.addFont(
      Future.value(ByteData.view(Uint8List.fromList(bytes).buffer)),
    );
  }
  await fontLoader.load();
}

/// Shared Flutter test bootstrap for Adaptive Cards packages.
Future<void> adaptiveCardsTestExecutable(
  FutureOr<void> Function() testMain, {
  String fontsRoot = 'assets/fonts/Roboto',
}) async {
  setUpAll(() async {
    HttpOverrides.global = MyTestHttpOverrides();
    await loadAdaptiveCardsTestFonts(fontsRoot: fontsRoot);
  });

  await testMain();
}
