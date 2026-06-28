import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_adaptive_cards_test_support/src/http_overrides.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_config/package_config.dart';

/// Loads Roboto fonts used by HostConfig-driven golden tests.
///
/// Fonts live under `assets/fonts/Roboto/` in this package. They are loaded
/// from the package directory so consuming packages can keep test_support in
/// `pubspec.yaml` `dev_dependencies` (dev-dependency assets are not merged into
/// the test bundle).
Future<void> loadAdaptiveCardsTestFonts() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  const fontNames = [
    'Roboto-Regular.ttf',
    'Roboto-Italic.ttf',
    'Roboto-Bold.ttf',
    'Roboto-BoldItalic.ttf',
    'Roboto-Light.ttf',
    'Roboto-LightItalic.ttf',
    'Roboto-Medium.ttf',
    'Roboto-MediumItalic.ttf',
    'Roboto-Thin.ttf',
    'Roboto-ThinItalic.ttf',
    'RobotoMono-Regular.ttf',
    'RobotoMono-Italic.ttf',
    'RobotoMono-Bold.ttf',
    'RobotoMono-BoldItalic.ttf',
    'RobotoMono-Light.ttf',
    'RobotoMono-LightItalic.ttf',
    'RobotoMono-Medium.ttf',
    'RobotoMono-MediumItalic.ttf',
    'RobotoMono-Thin.ttf',
    'RobotoMono-ThinItalic.ttf',
  ];

  final fontsDir = await _resolveRobotoFontsDirectory();

  final fontLoader = FontLoader('Roboto');
  for (final name in fontNames) {
    fontLoader.addFont(
      File('${fontsDir.path}/$name').readAsBytes().then(ByteData.sublistView),
    );
  }
  await fontLoader.load();
}

/// Loads fonts bundled into the test asset bundle via `FontManifest.json`.
///
/// Crucially this includes **MaterialIcons** (present because the consuming
/// package sets `uses-material-design: true`), which backs the Adaptive Cards
/// `Icon`/`Badge`/rating glyphs. Without it golden images render icons as empty
/// tofu boxes. Any package-declared fonts in the manifest are loaded too.
Future<void> loadBundledTestFonts() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  final manifestRaw = await rootBundle.loadString('FontManifest.json');
  final manifest = (json.decode(manifestRaw) as List<dynamic>)
      .cast<Map<String, dynamic>>();

  for (final font in manifest) {
    final family = _deriveFontFamily(font['family'] as String);
    final loader = FontLoader(family);
    for (final asset in (font['fonts'] as List<dynamic>)
        .cast<Map<String, dynamic>>()) {
      loader.addFont(rootBundle.load(asset['asset'] as String));
    }
    await loader.load();
  }
}

/// Strips the `packages/<name>/` prefix the font tool adds to packaged
/// font families so the loaded family name matches the resolved `IconData`.
String _deriveFontFamily(String family) {
  final match = RegExp(r'^packages/[^/]+/(.+)$').firstMatch(family);
  return match?.group(1) ?? family;
}

Future<Directory> _resolveRobotoFontsDirectory() async {
  final config = await findPackageConfig(Directory.current);
  if (config == null) {
    throw StateError('Package config not found (run from a Flutter package).');
  }

  final package = config['flutter_adaptive_cards_test_support'];
  if (package == null) {
    throw StateError(
      'flutter_adaptive_cards_test_support is not in package config.',
    );
  }

  final fontsDir = Directory.fromUri(
    package.root.resolve('assets/fonts/Roboto/'),
  );
  // sync method fails
  // ignore: avoid_slow_async_io
  if (!await fontsDir.exists()) {
    throw StateError('Roboto fonts not found at ${fontsDir.path}');
  }
  return fontsDir;
}

/// Shared Flutter test bootstrap for Adaptive Cards packages.
Future<void> adaptiveCardsTestExecutable(
  FutureOr<void> Function() testMain,
) async {
  setUpAll(() async {
    HttpOverrides.global = MyTestHttpOverrides();
    await loadAdaptiveCardsTestFonts();
    await loadBundledTestFonts();
  });

  await testMain();
}
