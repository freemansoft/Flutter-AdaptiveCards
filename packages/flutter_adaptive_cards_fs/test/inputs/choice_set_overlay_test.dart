import 'package:flutter_adaptive_cards_fs/src/cards/inputs/choice_set.dart';
import 'package:flutter_adaptive_cards_fs/src/flutter_raw_adaptive_card.dart';
import 'package:flutter_adaptive_cards_fs/src/models/choice.dart';
import 'package:flutter_adaptive_cards_fs/src/riverpod/providers.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

RawAdaptiveCardState _cardState(WidgetTester tester) {
  return tester.state<RawAdaptiveCardState>(find.byType(RawAdaptiveCard));
}

/// Minimal expanded `Input.ChoiceSet` card used across overlay widget tests.
Map<String, dynamic> choiceSetOverlayTestCard(
  List<Map<String, dynamic>> choices, {
  String id = 'myChoice',
}) {
  return {
    'type': 'AdaptiveCard',
    'version': '1.3',
    'body': [
      {
        'type': 'Input.ChoiceSet',
        'id': id,
        'style': 'expanded',
        'choices': choices,
      },
    ],
  };
}

Map<String, dynamic> _choiceSetElementMap(Map<String, dynamic> card) {
  return card['body'][0] as Map<String, dynamic>;
}

void main() {
  testWidgets('loadInput replaces ChoiceSet options via document overlay', (
    WidgetTester tester,
  ) async {
    final map = choiceSetOverlayTestCard([
      {'title': 'Original', 'value': 'orig'},
    ]);

    await tester.pumpWidget(
      getTestWidgetFromMap(map: map, title: 'ChoiceSet loadInput overlay test'),
    );
    await tester.pumpAndSettle();

    final elementMap = _choiceSetElementMap(map);
    expect(
      find.byKey(generateWidgetKey(elementMap, suffix: 'Original')),
      findsOneWidget,
    );

    _cardState(tester).loadInput('myChoice', {
      'Dynamic A': 'a',
      'Dynamic B': 'b',
    });
    await tester.pumpAndSettle();

    expect(
      find.byKey(generateWidgetKey(elementMap, suffix: 'Original')),
      findsNothing,
    );
    expect(
      find.byKey(generateWidgetKey(elementMap, suffix: 'Dynamic A')),
      findsOneWidget,
    );
    expect(
      find.byKey(generateWidgetKey(elementMap, suffix: 'Dynamic B')),
      findsOneWidget,
    );
  });

  testWidgets('appendChoices adds options without removing baseline static', (
    WidgetTester tester,
  ) async {
    final map = choiceSetOverlayTestCard([
      {'title': 'Static', 'value': 'static'},
    ]);

    await tester.pumpWidget(getTestWidgetFromMap(map: map, title: 'append'));
    await tester.pumpAndSettle();

    final elementMap = _choiceSetElementMap(map);
    final staticKey = generateWidgetKey(elementMap, suffix: 'Static');
    expect(find.byKey(staticKey), findsOneWidget);

    final container = ProviderScope.containerOf(
      tester.element(find.byKey(staticKey)),
    );
    container.read(adaptiveCardDocumentProvider.notifier).appendChoices(
      'myChoice',
      const [
        Choice(title: 'Dynamic', value: 'dynamic'),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.byKey(staticKey), findsOneWidget);
    expect(
      find.byKey(generateWidgetKey(elementMap, suffix: 'Dynamic')),
      findsOneWidget,
    );
  });

  testWidgets('resetAllInputs clears dynamic choices overlay', (
    WidgetTester tester,
  ) async {
    final map = choiceSetOverlayTestCard([
      {'title': 'Static', 'value': 'static'},
    ]);

    await tester.pumpWidget(
      getTestWidgetFromMap(map: map, title: 'reset choices overlay'),
    );
    await tester.pumpAndSettle();

    final elementMap = _choiceSetElementMap(map);

    _cardState(tester).loadInput('myChoice', {'Only Dynamic': 'dyn'});
    await tester.pumpAndSettle();
    expect(
      find.byKey(generateWidgetKey(elementMap, suffix: 'Only Dynamic')),
      findsOneWidget,
    );

    final container = ProviderScope.containerOf(
      tester.element(
        find.byKey(generateWidgetKey(elementMap, suffix: 'Only Dynamic')),
      ),
    );
    container.read(adaptiveCardDocumentProvider.notifier).resetAllInputs();
    await tester.pumpAndSettle();

    expect(
      find.byKey(generateWidgetKey(elementMap, suffix: 'Static')),
      findsOneWidget,
    );
    expect(
      find.byKey(generateWidgetKey(elementMap, suffix: 'Only Dynamic')),
      findsNothing,
    );
  });

  testWidgets('loadInput clears selection and value overlay', (
    WidgetTester tester,
  ) async {
    final map = choiceSetOverlayTestCard([
      {'title': 'Original', 'value': 'orig'},
    ]);

    await tester.pumpWidget(
      getTestWidgetFromMap(map: map, title: 'loadInput clears selection'),
    );
    await tester.pumpAndSettle();

    final elementMap = _choiceSetElementMap(map);
    await tester.tap(
      find.byKey(generateWidgetKey(elementMap, suffix: 'Original')),
    );
    await tester.pumpAndSettle();

    final choiceState = tester.state<AdaptiveChoiceSetState>(
      find.byType(AdaptiveChoiceSet),
    );
    final Map<String, dynamic> selected = {};
    choiceState.appendInput(selected);
    expect(selected['myChoice'], 'orig');

    _cardState(tester).loadInput('myChoice', {'New Only': 'new'});
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(
        find.byKey(generateWidgetKey(elementMap, suffix: 'New Only')),
      ),
    );
    final doc = container.read(adaptiveCardDocumentProvider);
    expect(doc.overlaysById['myChoice']?.choices, isNotNull);
    expect(doc.overlaysById['myChoice']?.inputValue, isNull);

    final resolved = container.read(resolvedElementProvider('myChoice'));
    expect(resolved?['value'], isNull);

    final Map<String, dynamic> cleared = {};
    choiceState.appendInput(cleared);
    expect(cleared['myChoice'], '');
  });

  testWidgets('loadInput updates resolved choices map', (
    WidgetTester tester,
  ) async {
    final map = choiceSetOverlayTestCard([
      {'title': 'Original', 'value': 'orig'},
    ]);

    await tester.pumpWidget(
      getTestWidgetFromMap(map: map, title: 'loadInput resolved choices'),
    );
    await tester.pumpAndSettle();

    _cardState(tester).loadInput('myChoice', {
      'Dynamic A': 'a',
      'Dynamic B': 'b',
    });
    await tester.pumpAndSettle();

    final elementMap = _choiceSetElementMap(map);
    final container = ProviderScope.containerOf(
      tester.element(
        find.byKey(generateWidgetKey(elementMap, suffix: 'Dynamic A')),
      ),
    );
    final choices =
        container.read(resolvedElementProvider('myChoice'))?['choices']
            as List<dynamic>?;
    expect(choices?.length, 2);
    final titles = choices!
        .map((c) => (c as Map<String, dynamic>)['title'] as String)
        .toList();
    expect(titles, containsAll(['Dynamic A', 'Dynamic B']));
  });

  testWidgets('appendChoices dedupes by value in resolved choices', (
    WidgetTester tester,
  ) async {
    final map = choiceSetOverlayTestCard([
      {'title': 'Static', 'value': 'static'},
    ]);

    await tester.pumpWidget(getTestWidgetFromMap(map: map, title: 'dedupe'));
    await tester.pumpAndSettle();

    final elementMap = _choiceSetElementMap(map);
    final staticKey = generateWidgetKey(elementMap, suffix: 'Static');
    final container = ProviderScope.containerOf(
      tester.element(find.byKey(staticKey)),
    );

    container.read(adaptiveCardDocumentProvider.notifier).appendChoices(
      'myChoice',
      const [
        Choice(title: 'Static Updated', value: 'static'),
      ],
    );
    await tester.pumpAndSettle();

    final choices =
        container.read(resolvedElementProvider('myChoice'))?['choices']
            as List<dynamic>?;
    expect(choices?.length, 1);
    expect((choices!.first as Map)['title'], 'Static Updated');
    expect((choices.first as Map)['value'], 'static');
  });
}
