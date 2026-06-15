import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/cards/elements/rating.dart';
import 'package:flutter_adaptive_cards_fs/src/flutter_raw_adaptive_card.dart';
import 'package:flutter_adaptive_cards_fs/src/models/adaptive_card_update.dart';
import 'package:flutter_adaptive_cards_fs/src/riverpod/providers.dart';
import 'package:flutter_adaptive_cards_fs/src/widgets/rating_stars.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

ProviderContainer _documentContainer(WidgetTester tester, Finder ratingFinder) {
  return ProviderScope.containerOf(tester.element(ratingFinder));
}

RatingStars _ratingStars(WidgetTester tester) {
  return tester.widget<RatingStars>(find.byType(RatingStars));
}

void main() {
  testWidgets('applyUpdates patches display Rating value overlay', (
    WidgetTester tester,
  ) async {
    final Map<String, dynamic> map = {
      'type': 'AdaptiveCard',
      'version': '1.6',
      'body': [
        {
          'type': 'Rating',
          'id': 'stars',
          'value': 2,
          'max': 5,
        },
      ],
    };

    await tester.pumpWidget(
      getTestWidgetFromMap(
        map: map,
        title: 'Rating value overlay',
      ),
    );
    await tester.pumpAndSettle();

    expect(_ratingStars(tester).value, 2);
    expect(find.byIcon(Icons.star), findsNWidgets(2));

    tester
        .state<RawAdaptiveCardState>(find.byType(RawAdaptiveCard))
        .applyUpdates(
          elements: const [
            AdaptiveElementUpdate(id: 'stars', value: 4.5),
          ],
        );
    await tester.pump();

    expect(_ratingStars(tester).value, 4.5);
    expect(find.byIcon(Icons.star), findsNWidgets(5));
    expect(find.byIcon(Icons.star_border), findsNothing);
  });

  testWidgets('setInputValue updates display Rating via overlay merge', (
    WidgetTester tester,
  ) async {
    final Map<String, dynamic> map = {
      'type': 'AdaptiveCard',
      'version': '1.6',
      'body': [
        {
          'type': 'Rating',
          'id': 'stars',
          'value': 1,
          'max': 5,
        },
      ],
    };

    await tester.pumpWidget(
      getTestWidgetFromMap(
        map: map,
        title: 'Rating setInputValue overlay',
      ),
    );
    await tester.pumpAndSettle();

    final ratingFinder = find.byWidgetPredicate(
      (widget) => widget is AdaptiveRating && widget.id == 'stars',
    );
    final container = _documentContainer(tester, ratingFinder);

    container
        .read(adaptiveCardDocumentProvider.notifier)
        .setInputValue('stars', 4);
    await tester.pump();

    expect(_ratingStars(tester).value, 4);
    expect(find.byIcon(Icons.star), findsNWidgets(4));
    expect(find.byIcon(Icons.star_border), findsOneWidget);
  });
}
