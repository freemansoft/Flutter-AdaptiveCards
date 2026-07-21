import 'package:flutter_adaptive_cards_fs/src/cards/elements/carousel.dart';
import 'package:flutter_test/flutter_test.dart';

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
}
