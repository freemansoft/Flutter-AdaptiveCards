import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';
import 'package:flutter_adaptive_cards_fs/src/cards/inputs/rating.dart';
import 'package:flutter_adaptive_cards_fs/src/flutter_raw_adaptive_card.dart';
import 'package:flutter_adaptive_cards_fs/src/models/adaptive_card_update.dart';
import 'package:flutter_adaptive_cards_fs/src/riverpod/providers.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

RawAdaptiveCardState _cardState(WidgetTester tester) {
  return tester.state<RawAdaptiveCardState>(find.byType(RawAdaptiveCard));
}

ProviderContainer _documentContainer(WidgetTester tester, Finder inputFinder) {
  return ProviderScope.containerOf(tester.element(inputFinder));
}

void main() {
  testWidgets('Input.Rating submits double value', (tester) async {
    SubmitActionInvoke? captured;

    const card = {
      'type': 'AdaptiveCard',
      'version': '1.6',
      'body': [
        {
          'type': 'Input.Rating',
          'id': 'rating',
          'max': 5,
        },
      ],
      'actions': [
        {
          'type': 'Action.Submit',
          'title': 'Submit',
        },
      ],
    };

    await tester.pumpWidget(
      getTestWidgetFromMap(
        map: card,
        title: 'rating submit test',
        onOpenUrl: (_) {},
        onSubmit: (invoke) => captured = invoke,
        onExecute: (_) {},
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.star_border).at(3));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Submit'));
    await tester.pumpAndSettle();

    expect(captured, isNotNull);
    expect(captured!.data['rating'], 4);
  });

  testWidgets('applyUpdates value and label update Input.Rating', (
    tester,
  ) async {
    final map = <String, dynamic>{
      'type': 'AdaptiveCard',
      'version': '1.6',
      'body': [
        {
          'type': 'Input.Rating',
          'id': 'rating',
          'label': 'Baseline label',
          'max': 5,
          'value': 0,
        },
      ],
    };

    await tester.pumpWidget(
      getTestWidgetFromMap(map: map, title: 'rating overlay label value'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Baseline label'), findsOneWidget);
    expect(find.byIcon(Icons.star), findsNothing);

    _cardState(tester).applyUpdates(
      elements: const [
        AdaptiveElementUpdate(
          id: 'rating',
          value: 3,
          label: 'Rate us',
        ),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.text('Rate us'), findsOneWidget);
    expect(find.text('Baseline label'), findsNothing);
    expect(find.byIcon(Icons.star), findsNWidgets(3));
  });

  testWidgets('setInputError shows on Input.Rating', (tester) async {
    final map = <String, dynamic>{
      'type': 'AdaptiveCard',
      'version': '1.6',
      'body': [
        {
          'type': 'Input.Rating',
          'id': 'rating',
          'label': 'Rating',
          'max': 5,
        },
      ],
    };

    await tester.pumpWidget(
      getTestWidgetFromMap(map: map, title: 'rating input error overlay'),
    );
    await tester.pumpAndSettle();

    final ratingMap = map['body'][0] as Map<String, dynamic>;
    final inputFinder = find.byKey(generateWidgetKey(ratingMap));
    final container = _documentContainer(tester, inputFinder);

    container
        .read(adaptiveCardDocumentProvider.notifier)
        .setInputError(
          'rating',
          errorMessage: 'Please select a rating',
          isInvalid: true,
        );
    await tester.pump();

    expect(find.text('Please select a rating'), findsOneWidget);
  });

  testWidgets('resetInput restores baseline value', (tester) async {
    final map = <String, dynamic>{
      'type': 'AdaptiveCard',
      'version': '1.6',
      'body': [
        {
          'type': 'Input.Rating',
          'id': 'rating',
          'label': 'Rating',
          'max': 5,
          'value': 2,
        },
      ],
    };

    await tester.pumpWidget(
      getTestWidgetFromMap(map: map, title: 'rating reset input'),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.star), findsNWidgets(2));

    await tester.tap(find.byIcon(Icons.star_border).last);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.star), findsNWidgets(5));

    final state = tester.state<AdaptiveRatingInputState>(
      find.byType(AdaptiveRatingInput),
    );
    state.resetInput();
    await tester.pump();

    expect(find.byIcon(Icons.star), findsNWidgets(2));
  });

  testWidgets('collectInputValues includes Input.Rating id with double value', (
    tester,
  ) async {
    final map = <String, dynamic>{
      'type': 'AdaptiveCard',
      'version': '1.6',
      'body': [
        {
          'type': 'Input.Rating',
          'id': 'rating',
          'max': 5,
        },
      ],
    };

    await tester.pumpWidget(
      getTestWidgetFromMap(map: map, title: 'rating collectInputValues'),
    );
    await tester.pumpAndSettle();

    final ratingMap = map['body'][0] as Map<String, dynamic>;
    final container = _documentContainer(
      tester,
      find.byKey(generateWidgetKey(ratingMap)),
    );

    await tester.tap(find.byIcon(Icons.star_border).at(2));
    await tester.pumpAndSettle();

    final values = container
        .read(adaptiveCardDocumentProvider.notifier)
        .collectInputValues();
    expect(values['rating'], 3);
  });
}
