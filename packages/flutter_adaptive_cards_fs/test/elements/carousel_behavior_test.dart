import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

Map<String, dynamic> _carousel({String? orientation, int? timer}) {
  return <String, dynamic>{
    'type': 'AdaptiveCard',
    'version': '1.5',
    'body': <Map<String, dynamic>>[
      {
        'type': 'Carousel',
        'orientation': ?orientation,
        'timer': ?timer,
        'pages': <Map<String, dynamic>>[
          {
            'type': 'CarouselPage',
            'items': <Map<String, dynamic>>[
              {'type': 'TextBlock', 'text': 'A'},
            ],
          },
          {
            'type': 'CarouselPage',
            'items': <Map<String, dynamic>>[
              {'type': 'TextBlock', 'text': 'B'},
            ],
          },
        ],
      },
    ],
  };
}

void main() {
  testWidgets('vertical orientation sets PageView scrollDirection', (
    tester,
  ) async {
    await tester.pumpWidget(
      getTestWidgetFromMap(
        map: _carousel(orientation: 'vertical'),
        title: 'v',
      ),
    );
    await tester.pump();

    final pageView = tester.widget<PageView>(find.byType(PageView));
    expect(pageView.scrollDirection, Axis.vertical);
  });

  testWidgets('default orientation is horizontal', (tester) async {
    await tester.pumpWidget(
      getTestWidgetFromMap(map: _carousel(), title: 'h'),
    );
    await tester.pump();

    expect(
      tester.widget<PageView>(find.byType(PageView)).scrollDirection,
      Axis.horizontal,
    );
  });

  testWidgets('timer auto-advances to the next page', (tester) async {
    await tester.pumpWidget(
      getTestWidgetFromMap(map: _carousel(timer: 1000), title: 't'),
    );
    await tester.pump();

    final controller = tester
        .widget<PageView>(find.byType(PageView))
        .controller!;
    expect(controller.page?.round() ?? controller.initialPage, 0);

    await tester.pump(const Duration(milliseconds: 1100));
    await tester.pumpAndSettle();

    expect(
      tester.widget<PageView>(find.byType(PageView)).controller!.page?.round(),
      1,
    );
  });
}
