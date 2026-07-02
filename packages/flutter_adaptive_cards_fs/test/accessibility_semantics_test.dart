import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/widgets/rating_stars.dart';
import 'package:flutter_test/flutter_test.dart';

import 'utils/test_utils.dart';

/// Accessibility-semantics regression tests for the core library.
///
/// Covers: decorative images excluded from semantics (no placeholder label),
/// `selectAction` targets announced as buttons with a name, Rating value
/// semantics, and carousel dot labels.
void main() {
  setUp(() {
    HttpOverrides.global = MyTestHttpOverrides();
  });

  Widget buildCard(Map<String, dynamic> map) => getTestWidgetFromMap(
    map: map,
    title: 'a test',
    onOpenUrl: (_) {},
    onSubmit: (_) {},
    onExecute: (_) {},
  );

  testWidgets(
    'Image without altText is not labeled "alt text not set"',
    (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        buildCard({
          'type': 'AdaptiveCard',
          'version': '1.0',
          'body': [
            {'type': 'Image', 'url': 'https://example.com/pic.png'},
          ],
        }),
      );
      await tester.pump();

      expect(find.bySemanticsLabel('alt text not set'), findsNothing);
      handle.dispose();
    },
  );

  testWidgets('Image with altText exposes it as a semantics label', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(
      buildCard({
        'type': 'AdaptiveCard',
        'version': '1.0',
        'body': [
          {
            'type': 'Image',
            'url': 'https://example.com/pic.png',
            'altText': 'A friendly logo',
          },
        ],
      }),
    );
    await tester.pump();

    expect(find.bySemanticsLabel('A friendly logo'), findsWidgets);
    handle.dispose();
  });

  testWidgets(
    'selectAction wrapper is announced as a button with the action title',
    (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        buildCard({
          'type': 'AdaptiveCard',
          'version': '1.0',
          'body': [
            {
              'type': 'Container',
              'id': 'c1',
              'selectAction': {
                'type': 'Action.OpenUrl',
                'title': 'Open details',
                'url': 'https://example.com',
              },
              'items': [
                {'type': 'TextBlock', 'text': 'row'},
              ],
            },
          ],
        }),
      );
      await tester.pumpAndSettle();

      // The button node merges the wrapped content into its label, so the
      // effective name is e.g. "Open details\nrow" — match on the action title
      // substring and assert the button role.
      final finder = find.bySemanticsLabel(RegExp('Open details'));
      expect(finder, findsOneWidget);
      expect(tester.getSemantics(finder), isSemantics(isButton: true));
      handle.dispose();
    },
  );

  testWidgets('read-only Rating exposes a "x of y stars" value', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(
      buildCard({
        'type': 'AdaptiveCard',
        'version': '1.0',
        'body': [
          {'type': 'Rating', 'value': 3, 'max': 5},
        ],
      }),
    );
    await tester.pumpAndSettle();

    final node = tester.getSemantics(find.byType(RatingStars));
    expect(node, isSemantics(value: '3 of 5 stars', isReadOnly: true));
    handle.dispose();
  });

  testWidgets(
    'interactive Input.Rating is adjustable with a value',
    (tester) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        buildCard({
          'type': 'AdaptiveCard',
          'version': '1.0',
          'body': [
            {'type': 'Input.Rating', 'id': 'r1', 'value': 2, 'max': 5},
          ],
        }),
      );
      await tester.pumpAndSettle();

      final node = tester.getSemantics(find.byType(RatingStars));
      expect(
        node,
        isSemantics(
          value: '2 of 5 stars',
          isSlider: true,
          hasIncreaseAction: true,
          hasDecreaseAction: true,
        ),
      );
      handle.dispose();
    },
  );

  testWidgets('carousel page dots expose a "Go to slide N" label', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(
      buildCard({
        'type': 'AdaptiveCard',
        'version': '1.0',
        'body': [
          {
            'type': 'Carousel',
            'id': 'car1',
            'pages': [
              {
                'type': 'CarouselPage',
                'items': [
                  {'type': 'TextBlock', 'text': 'p1'},
                ],
              },
              {
                'type': 'CarouselPage',
                'items': [
                  {'type': 'TextBlock', 'text': 'p2'},
                ],
              },
            ],
          },
        ],
      }),
    );
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Go to slide 1'), findsOneWidget);
    expect(find.bySemanticsLabel('Go to slide 2'), findsOneWidget);
    handle.dispose();
  });
}
