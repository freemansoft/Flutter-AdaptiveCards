import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/flutter_raw_adaptive_card.dart';
import 'package:flutter_adaptive_cards_fs/src/riverpod/providers.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

RawAdaptiveCardState _cardState(WidgetTester tester) {
  return tester.state<RawAdaptiveCardState>(find.byType(RawAdaptiveCard));
}

ProviderContainer _documentContainer(WidgetTester tester, Finder finder) {
  return ProviderScope.containerOf(tester.element(finder));
}

void main() {
  testWidgets('setIsRequired overlay updates resolved element and label', (
    WidgetTester tester,
  ) async {
    final map = <String, dynamic>{
      'type': 'AdaptiveCard',
      'body': [
        {
          'type': 'Input.Text',
          'id': 'optionalField',
          'label': 'Name',
          'isRequired': false,
        },
      ],
    };

    await tester.pumpWidget(
      getTestWidgetFromMap(map: map, title: 'isRequired overlay'),
    );
    await tester.pumpAndSettle();

    final textMap = map['body'][0] as Map<String, dynamic>;
    final inputFinder = find.byKey(generateWidgetKey(textMap));
    final container = _documentContainer(tester, inputFinder);
    expect(
      container.read(resolvedElementProvider('optionalField'))?['isRequired'],
      isFalse,
    );

    container
        .read(adaptiveCardDocumentProvider.notifier)
        .setIsRequired('optionalField', required: true);
    await tester.pump();

    expect(
      container.read(resolvedElementProvider('optionalField'))?['isRequired'],
      isTrue,
    );

    _cardState(tester).applyUpdatesFromMap({
      'optionalField': {'isRequired': false},
    });
    await tester.pump();

    expect(
      container.read(resolvedElementProvider('optionalField'))?['isRequired'],
      isFalse,
    );
  });
}
