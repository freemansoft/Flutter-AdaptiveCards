import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseHexColor', () {
    test('parses #AARRGGBB (9 chars)', () {
      expect(parseHexColor('#80112233'), const Color(0x80112233));
    });

    test('parses AARRGGBB without leading # (8 chars)', () {
      expect(parseHexColor('80112233'), const Color(0x80112233));
    });

    test('returns null for null input', () {
      expect(parseHexColor(null), isNull);
    });

    test('throws on an invalid length', () {
      expect(() => parseHexColor('#123'), throwsStateError);
    });
  });

  group('small helpers', () {
    test('firstCharacterToLowerCase lowercases only the first character', () {
      expect(firstCharacterToLowerCase('Hello'), 'hello');
      expect(firstCharacterToLowerCase(''), '');
    });

    test('Tuple holds its two components', () {
      final tuple = Tuple<int, String>(1, 'a');
      expect(tuple.a, 1);
      expect(tuple.b, 'a');
    });

    test('FullCircleClipper clips to full bounds and never reclips', () {
      const clipper = FullCircleClipper();
      expect(
        clipper.getClip(const Size(10, 20)),
        const Rect.fromLTWH(0, 0, 10, 20),
      );
      expect(clipper.shouldReclip(const FullCircleClipper()), isFalse);
    });

    test('parseMinHeight parses a plain numeric string', () {
      expect(parseMinHeight('120'), 120.0);
    });
  });

  testWidgets('FadeAnimation animates, updates on child change, and disposes', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: FadeAnimation(
          duration: Duration(milliseconds: 100),
          child: Text('first'),
        ),
      ),
    );

    // While animating, the build path wraps the child in an Opacity.
    expect(find.byType(Opacity), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 20));

    // A new child reuses the State and re-runs didUpdateWidget -> forward().
    await tester.pumpWidget(
      const MaterialApp(
        home: FadeAnimation(
          duration: Duration(milliseconds: 100),
          child: Text('second'),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 20));

    // Once the animation completes, build returns a plain Container.
    await tester.pumpAndSettle();
    expect(find.byType(Opacity), findsNothing);

    // Removing the widget exercises deactivate + dispose.
    await tester.pumpWidget(const SizedBox());
  });
}
