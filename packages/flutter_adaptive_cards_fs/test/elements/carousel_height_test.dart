import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/cards/elements/carousel.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

Map<String, dynamic> _carouselCard({
  required List<Map<String, dynamic>> pages,
  String? heightProp,
  String? heightInPixels,
  String? orientation,
}) => <String, dynamic>{
  'type': 'AdaptiveCard',
  'version': '1.6',
  'body': <Map<String, dynamic>>[
    <String, dynamic>{
      'type': 'Carousel',
      'id': 'car1',
      'height': ?heightProp,
      'heightInPixels': ?heightInPixels,
      'orientation': ?orientation,
      'pages': pages,
    },
  ],
};

Map<String, dynamic> _page(String id, int lines) => <String, dynamic>{
  'type': 'CarouselPage',
  'id': id,
  'items': <Map<String, dynamic>>[
    for (int i = 0; i < lines; i++)
      <String, dynamic>{'type': 'TextBlock', 'text': 'line $i of $id'},
  ],
};

double _carouselHeight(WidgetTester tester) =>
    tester.getSize(find.byType(PageView)).height;

void main() {
  group('resolveCarouselHeight', () {
    test('explicit heightInPixels wins over everything else', () {
      expect(
        resolveCarouselHeight(
          heightInPixels: 100,
          isStretch: true,
          maxAvailableHeight: 800,
          measuredMaxHeight: 250,
          fallback: 400,
        ),
        100,
      );
    });

    test('stretch fills a finite parent height', () {
      expect(
        resolveCarouselHeight(
          heightInPixels: null,
          isStretch: true,
          maxAvailableHeight: 800,
          measuredMaxHeight: 250,
          fallback: 400,
        ),
        800,
      );
    });

    test('stretch under an unbounded parent falls back to measured max', () {
      expect(
        resolveCarouselHeight(
          heightInPixels: null,
          isStretch: true,
          maxAvailableHeight: double.infinity,
          measuredMaxHeight: 250,
          fallback: 400,
        ),
        250,
      );
    });

    test('auto uses the measured tallest page when available', () {
      expect(
        resolveCarouselHeight(
          heightInPixels: null,
          isStretch: false,
          maxAvailableHeight: 800,
          measuredMaxHeight: 250,
          fallback: 400,
        ),
        250,
      );
    });

    test('auto uses the fallback before any measurement', () {
      expect(
        resolveCarouselHeight(
          heightInPixels: null,
          isStretch: false,
          maxAvailableHeight: 800,
          measuredMaxHeight: null,
          fallback: 400,
        ),
        400,
      );
    });
  });

  group('carousel widget height', () {
    testWidgets('heightInPixels sets an exact fixed height', (tester) async {
      await tester.pumpWidget(
        getTestWidgetFromMap(
          map: _carouselCard(
            heightInPixels: '100px',
            pages: <Map<String, dynamic>>[_page('a', 1), _page('b', 8)],
          ),
          title: 'fixed px',
        ),
      );
      await tester.pumpAndSettle();

      expect(_carouselHeight(tester), 100);
    });

    testWidgets(
      'auto height equals the tallest page and is order-independent',
      (tester) async {
        final short = _page('short', 1);
        final tall = _page('tall', 8);

        Future<double> heightFor(List<Map<String, dynamic>> pages) async {
          // Unmount the previous card so the canvas re-inits fresh; it only
          // loads content once in initState, so re-pumping a new map into
          // the same tree would otherwise keep rendering stale content.
          await tester.pumpWidget(const SizedBox());
          await tester.pumpWidget(
            getTestWidgetFromMap(
              map: _carouselCard(pages: pages),
              title: 'auto',
            ),
          );
          await tester.pumpAndSettle();
          return _carouselHeight(tester);
        }

        final hShort = await heightFor(<Map<String, dynamic>>[short]);
        final hTall = await heightFor(<Map<String, dynamic>>[tall]);
        final hShortTall = await heightFor(<Map<String, dynamic>>[short, tall]);
        final hTallShort = await heightFor(<Map<String, dynamic>>[tall, short]);

        expect(hTall, greaterThan(hShort)); // pages really differ
        final expectedMax = hTall > hShort ? hTall : hShort;
        expect(hShortTall, closeTo(expectedMax, 0.5)); // == tallest page
        expect(hTallShort, closeTo(hShortTall, 0.5)); // order-independent
        expect(
          hShortTall,
          lessThan(400),
        ); // content-sized, not the old fixed 400
      },
    );

    testWidgets('vertical auto carousel renders a non-zero content height', (
      tester,
    ) async {
      await tester.pumpWidget(
        getTestWidgetFromMap(
          map: _carouselCard(
            orientation: 'vertical',
            pages: <Map<String, dynamic>>[_page('a', 2), _page('b', 5)],
          ),
          title: 'vertical auto',
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester.widget<PageView>(find.byType(PageView)).scrollDirection,
        Axis.vertical,
      );
      expect(_carouselHeight(tester), greaterThan(0));
    });

    testWidgets(
      'negative heightInPixels is ignored and falls back to content height',
      (tester) async {
        await tester.pumpWidget(
          getTestWidgetFromMap(
            map: _carouselCard(
              heightInPixels: '-50px',
              pages: <Map<String, dynamic>>[_page('a', 1), _page('b', 8)],
            ),
            title: 'negative px',
          ),
        );
        await tester.pumpAndSettle();

        // A negative heightInPixels must not be honored (it would crash
        // SizedBox(height: -50)); it should fall back to the measured
        // tallest-page height instead, which is content-sized (well under
        // the old fixed 400 fallback).
        expect(_carouselHeight(tester), greaterThan(0));
        expect(_carouselHeight(tester), lessThan(400));
      },
    );

    testWidgets(
      'height "stretch" under an unbounded parent behaves like auto',
      (tester) async {
        final short = _page('short', 1);
        final tall = _page('tall', 8);

        await tester.pumpWidget(
          getTestWidgetFromMap(
            map: _carouselCard(pages: <Map<String, dynamic>>[tall]),
            title: 'tall reference',
          ),
        );
        await tester.pumpAndSettle();
        final hTall = _carouselHeight(tester);

        // Unmount so the stretch build re-inits fresh (see the auto test's
        // note above about content only loading once in initState).
        await tester.pumpWidget(const SizedBox());
        await tester.pumpWidget(
          getTestWidgetFromMap(
            map: _carouselCard(
              heightProp: 'stretch',
              pages: <Map<String, dynamic>>[short, tall],
            ),
            title: 'stretch',
          ),
        );
        await tester.pumpAndSettle();

        expect(_carouselHeight(tester), closeTo(hTall, 0.5));
      },
    );
  });
}
