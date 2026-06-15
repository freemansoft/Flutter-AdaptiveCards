import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/flutter_raw_adaptive_card.dart';
import 'package:flutter_adaptive_cards_fs/src/models/adaptive_card_update.dart';
import 'package:flutter_adaptive_cards_fs/src/riverpod/providers.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

ProviderContainer _documentContainer(WidgetTester tester, Finder inputFinder) {
  return ProviderScope.containerOf(tester.element(inputFinder));
}

void main() {
  testWidgets('initData seeds toggle overlay with bool value', (
    WidgetTester tester,
  ) async {
    final Map<String, dynamic> map = {
      'type': 'AdaptiveCard',
      'body': [
        {
          'type': 'Input.Toggle',
          'id': 'initToggle',
          'title': 'Init Toggle',
        },
      ],
    };

    await tester.pumpWidget(
      getTestWidgetFromMap(
        map: map,
        title: 'initData toggle overlay',
        initData: const {'initToggle': true},
      ),
    );
    await tester.pumpAndSettle();

    final toggleMap = map['body'][0] as Map<String, dynamic>;
    final inputFinder = find.byKey(generateWidgetKey(toggleMap));
    final container = _documentContainer(tester, inputFinder);

    expect(
      container.read(resolvedElementProvider('initToggle'))?['value'],
      isTrue,
    );

    final sw = tester.widget<Switch>(inputFinder);
    expect(sw.value, isTrue);
  });

  testWidgets('applyUpdates patches label isRequired and errorMessage', (
    WidgetTester tester,
  ) async {
    final map = <String, dynamic>{
      'type': 'AdaptiveCard',
      'body': [
        {
          'type': 'Input.Toggle',
          'id': 'agree',
          'title': 'Baseline title',
          'value': 'false',
          'valueOn': 'true',
          'valueOff': 'false',
        },
      ],
    };
    await tester.pumpWidget(
      getTestWidgetFromMap(map: map, title: 'toggle overlay'),
    );
    await tester.pumpAndSettle();

    final toggleMap = map['body'][0] as Map<String, dynamic>;
    final inputFinder = find.byKey(generateWidgetKey(toggleMap));
    final container = _documentContainer(tester, inputFinder);

    tester
        .state<RawAdaptiveCardState>(find.byType(RawAdaptiveCard))
        .applyUpdates(
          elements: const [
            AdaptiveElementUpdate(
              id: 'agree',
              label: 'I agree to terms',
              isRequired: true,
              errorMessage: 'Required',
              isInvalid: true,
            ),
          ],
        );
    await tester.pump();

    expect(find.textContaining('I agree to terms'), findsOneWidget);
    expect(find.text('Baseline title'), findsNothing);
    expect(find.text('Required'), findsOneWidget);
    expect(
      container.read(resolvedElementProvider('agree'))?['isInvalid'],
      isTrue,
    );
    expect(
      container.read(resolvedElementProvider('agree'))?['label'],
      'I agree to terms',
    );
    expect(
      container.read(resolvedElementProvider('agree'))?['isRequired'],
      isTrue,
    );
  });
}
