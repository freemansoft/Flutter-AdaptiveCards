import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/cards/inputs/date.dart';
import 'package:flutter_adaptive_cards_fs/src/flutter_raw_adaptive_card.dart';
import 'package:flutter_adaptive_cards_fs/src/riverpod/providers.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

ProviderContainer _documentContainer(WidgetTester tester, Finder inputFinder) {
  return ProviderScope.containerOf(tester.element(inputFinder));
}

RawAdaptiveCardState _cardState(WidgetTester tester) {
  return tester.state<RawAdaptiveCardState>(find.byType(RawAdaptiveCard));
}

void main() {
  testWidgets(
    'initData seeds date overlay visible in resolvedElementProvider',
    (
      WidgetTester tester,
    ) async {
      final Map<String, dynamic> map = {
        'type': 'AdaptiveCard',
        'body': [
          {
            'type': 'Input.Date',
            'id': 'bookingdate',
            'label': 'Booking Date',
            'placeholder': 'Enter your booking date',
          },
        ],
      };

      await tester.pumpWidget(
        getTestWidgetFromMap(
          map: map,
          title: 'initData date overlay',
          initData: const {'bookingdate': '2023-05-08'},
        ),
      );
      await tester.pumpAndSettle();

      final dateMap = map['body'][0] as Map<String, dynamic>;
      final inputFinder = find.byKey(generateWidgetKey(dateMap));
      final container = _documentContainer(tester, inputFinder);

      expect(
        container.read(resolvedElementProvider('bookingdate'))?['value'],
        '2023-05-08',
      );

      final field = tester.widget<TextFormField>(inputFinder);
      expect(field.controller!.text, '2023-05-08');

      final state = tester.state<AdaptiveDateInputState>(
        find.byType(AdaptiveDateInput),
      );
      expect(state.selectedDateTime, isNotNull);
      expect(state.selectedDateTime!.year, 2023);
      expect(state.selectedDateTime!.month, 5);
      expect(state.selectedDateTime!.day, 8);

      final out = <String, dynamic>{};
      state.appendInput(out);
      expect(out['bookingdate'], '2023-05-08');
    },
  );

  testWidgets('programmatic initInput updates date field after mount', (
    WidgetTester tester,
  ) async {
    final Map<String, dynamic> map = {
      'type': 'AdaptiveCard',
      'body': [
        {
          'type': 'Input.Date',
          'id': 'lateDate',
          'label': 'Late',
        },
      ],
    };

    await tester.pumpWidget(
      getTestWidgetFromMap(map: map, title: 'programmatic initInput date'),
    );
    await tester.pumpAndSettle();

    _cardState(tester).initInput({'lateDate': '2024-06-15'});
    await tester.pumpAndSettle();

    final dateMap = map['body'][0] as Map<String, dynamic>;
    final inputFinder = find.byKey(generateWidgetKey(dateMap));
    final container = _documentContainer(tester, inputFinder);

    expect(
      container.read(resolvedElementProvider('lateDate'))?['value'],
      '2024-06-15',
    );

    final field = tester.widget<TextFormField>(inputFinder);
    expect(field.controller!.text, '2024-06-15');

    final state = tester.state<AdaptiveDateInputState>(
      find.byType(AdaptiveDateInput),
    );
    expect(state.selectedDateTime, isNotNull);
  });
}
