import 'dart:io';

import 'package:test/test.dart';

// Relative: both files live outside lib/.
import '../tool/blog/pin_svg_light.dart';

// pin_svg_light.dart keeps draw.io diagrams readable in GitHub's dark theme by
// replacing each light-dark() colour with its light half. The cases cover the
// argument shapes draw.io actually exports, and the committed diagrams.
void main() {
  group('pinLightColors', () {
    test('replaces a hex pair with its light colour', () {
      expect(
        pinLightColors('fill: light-dark(#FFFFFF, #121212);'),
        'fill: #FFFFFF;',
      );
    });

    test('splits at the top-level comma when arguments nest', () {
      expect(
        pinLightColors(
          'fill: light-dark(rgb(255, 255, 255), rgb(18, 18, 18));',
        ),
        'fill: rgb(255, 255, 255);',
      );
      expect(
        pinLightColors(
          'background-color: light-dark(#ffffff, '
          'var(--ge-dark-color, #121212));',
        ),
        'background-color: #ffffff;',
      );
    });

    test('replaces every call, not only the first', () {
      expect(
        pinLightColors('a: light-dark(#000, #fff); b: light-dark(#111, #eee)'),
        'a: #000; b: #111',
      );
    });

    test('narrows the root colour scheme to light', () {
      expect(
        pinLightColors('style="color-scheme: light dark;"'),
        'style="color-scheme: light;"',
      );
    });

    test('changes nothing when applied to its own output', () {
      const svg =
          '<svg style="background-color: light-dark(#FFFFFF, #121212); '
          'color-scheme: light dark;"/>';
      final once = pinLightColors(svg);
      expect(pinLightColors(once), once);
    });

    test('rejects an unclosed call rather than truncating the file', () {
      expect(
        () => pinLightColors('fill: light-dark(#fff, #000'),
        throwsFormatException,
      );
    });
  });

  // The committed diagrams are what GitHub serves, so they are checked here as
  // well as by the CI step: `dart test` catches a fresh draw.io export locally.
  test('every committed blog diagram is already pinned', () {
    for (final file in drawioSvgs(Directory('blog'))) {
      final svg = file.readAsStringSync();
      expect(pinLightColors(svg), svg, reason: '${file.path} is not pinned');
    }
  });
}
