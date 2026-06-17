import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/cards/elements/carousel.dart';
import 'package:flutter_adaptive_cards_fs/src/riverpod/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

Visibility _visibilityOf(WidgetTester tester, Finder widgetFinder) =>
    tester.widget<Visibility>(
      find
          .descendant(of: widgetFinder, matching: find.byType(Visibility))
          .first,
    );

const Map<String, dynamic> _carouselMap = {
  'type': 'AdaptiveCard',
  'version': '1.6',
  'body': [
    {
      'type': 'Carousel',
      'id': 'car1',
      'pages': [
        {
          'type': 'CarouselPage',
          'items': [
            {'type': 'TextBlock', 'text': 'Page one'},
          ],
        },
      ],
    },
  ],
};

void main() {
  testWidgets('isVisible: false in JSON hides Carousel', (
    WidgetTester tester,
  ) async {
    final hiddenMap = {
      'type': 'AdaptiveCard',
      'version': '1.6',
      'body': [
        {
          'type': 'Carousel',
          'id': 'car1',
          'isVisible': false,
          'pages': [
            {
              'type': 'CarouselPage',
              'items': [
                {'type': 'TextBlock', 'text': 'Page one'},
              ],
            },
          ],
        },
      ],
    };

    await tester.pumpWidget(
      getTestWidgetFromMap(
        map: hiddenMap,
        title: 'carousel visibility static',
      ),
    );
    await tester.pumpAndSettle();

    final finder = find.byWidgetPredicate(
      (w) => w is AdaptiveCarousel && w.id == 'car1',
    );
    expect(_visibilityOf(tester, finder).visible, isFalse);
  });

  testWidgets('setVisibility toggles Carousel visibility', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      getTestWidgetFromMap(
        map: _carouselMap,
        title: 'carousel visibility overlay',
      ),
    );
    await tester.pumpAndSettle();

    final finder = find.byWidgetPredicate(
      (w) => w is AdaptiveCarousel && w.id == 'car1',
    );
    expect(_visibilityOf(tester, finder).visible, isTrue);

    final notifier = ProviderScope.containerOf(
      tester.element(finder),
    ).read(adaptiveCardDocumentProvider.notifier);

    Future<void> setVis({required bool visible}) async {
      notifier.setVisibility('car1', visible: visible);
      await tester.pump();
    }

    await setVis(visible: false);
    expect(_visibilityOf(tester, finder).visible, isFalse);

    await setVis(visible: true);
    expect(_visibilityOf(tester, finder).visible, isTrue);
  });
}
