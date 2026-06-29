import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/cards/elements/carousel.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

Map<String, dynamic> _carouselCard({bool showBorder = false}) => {
  'type': 'AdaptiveCard',
  'version': '1.6',
  'body': [
    {
      'type': 'Carousel',
      'id': 'car1',
      'pages': [
        {
          'type': 'CarouselPage',
          'id': 'page1',
          'showBorder': showBorder,
          'items': [
            {'type': 'TextBlock', 'text': 'Page one content'},
          ],
        },
      ],
    },
  ],
};

void main() {
  testWidgets('renders the page child items', (tester) async {
    await tester.pumpWidget(
      getTestWidgetFromMap(
        map: _carouselCard(),
        title: 'carousel page content',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AdaptiveCarouselPage), findsOneWidget);
    expect(find.text('Page one content'), findsOneWidget);
  });

  testWidgets('showBorder draws a bordered container around the page', (
    tester,
  ) async {
    await tester.pumpWidget(
      getTestWidgetFromMap(
        map: _carouselCard(showBorder: true),
        title: 'carousel page border',
      ),
    );
    await tester.pumpAndSettle();

    final container = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(AdaptiveCarouselPage),
            matching: find.byType(Container),
          )
          .first,
    );
    final decoration = container.decoration as BoxDecoration?;
    expect(decoration?.border, isNotNull);
  });
}
