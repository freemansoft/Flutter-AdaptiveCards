import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';
import 'package:flutter_adaptive_cards_fs/src/cards/elements/carousel.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

Map<String, dynamic> _carouselCard({
  bool showBorder = false,
  Map<String, dynamic>? selectAction,
}) => {
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
          'selectAction': ?selectAction,
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

  testWidgets('CarouselPage selectAction (OpenUrl) fires the handler', (
    tester,
  ) async {
    OpenUrlActionInvoke? captured;

    await tester.pumpWidget(
      getTestWidgetFromMap(
        map: _carouselCard(
          selectAction: {
            'type': 'Action.OpenUrl',
            'id': 'page-open',
            'url': 'https://example.com/page',
          },
        ),
        title: 'carousel page selectAction',
        onOpenUrl: (invoke) => captured = invoke,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Page one content'));
    await tester.pumpAndSettle();

    expect(captured, isNotNull);
    expect(captured!.actionId, 'page-open');
    expect(captured!.url, 'https://example.com/page');
  });

  testWidgets('v1.6/carousel.json sample: page selectAction fires', (
    tester,
  ) async {
    OpenUrlActionInvoke? captured;

    await tester.pumpWidget(
      getTestWidgetFromPath(
        path: 'v1.6/carousel.json',
        onOpenUrl: (invoke) => captured = invoke,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('PAGE 1'));
    await tester.pumpAndSettle();

    expect(captured, isNotNull);
    expect(captured!.url, 'https://adaptivecards.io/');
  });
}
