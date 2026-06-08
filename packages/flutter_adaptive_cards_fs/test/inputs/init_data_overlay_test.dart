import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/cards/inputs/choice_set.dart';
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
    'initData seeds text overlay visible in resolvedElementProvider',
    (
      WidgetTester tester,
    ) async {
      final Map<String, dynamic> map = {
        'type': 'AdaptiveCard',
        'body': [
          {
            'type': 'Input.Text',
            'id': 'initText',
            'label': 'Init',
          },
        ],
      };

      await tester.pumpWidget(
        getTestWidgetFromMap(
          map: map,
          title: 'initData text overlay',
          initData: const {'initText': 'initial value'},
        ),
      );
      await tester.pumpAndSettle();

      final textMap = map['body'][0] as Map<String, dynamic>;
      final inputFinder = find.byKey(generateWidgetKey(textMap));
      final container = _documentContainer(tester, inputFinder);

      expect(
        container.read(resolvedElementProvider('initText'))?['value'],
        'initial value',
      );

      final field = tester.widget<TextFormField>(inputFinder);
      expect(field.controller!.text, 'initial value');
    },
  );

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

  testWidgets(
    'initData seeds ChoiceSet selection when card has choices.data',
    (WidgetTester tester) async {
      final Map<String, dynamic> map = {
        'type': 'AdaptiveCard',
        'body': [
          {
            'type': 'Input.ChoiceSet',
            'id': 'myChoice',
            'style': 'expanded',
            'choices': [
              {'title': 'Choice 1', 'value': '1'},
              {'title': 'Choice 2', 'value': '2'},
            ],
            'choices.data': {
              'type': 'Data.Query',
              'dataset': 'example.com/items',
            },
          },
        ],
      };

      await tester.pumpWidget(
        getTestWidgetFromMap(
          map: map,
          title: 'initData choice with Data.Query',
          initData: const {'myChoice': '2'},
        ),
      );
      await tester.pumpAndSettle();

      final choiceMap = map['body'][0] as Map<String, dynamic>;
      final inputFinder = find.byKey(
        generateWidgetKey(choiceMap, suffix: 'Choice 2'),
      );
      final container = _documentContainer(tester, inputFinder);

      expect(
        container.read(resolvedElementProvider('myChoice'))?['value'],
        '2',
      );
      final choicesData =
          container.read(resolvedElementProvider('myChoice'))?['choices.data']
              as Map<String, dynamic>?;
      expect(choicesData?['dataset'], 'example.com/items');
    },
  );

  testWidgets('initData seeds ChoiceSet selection in resolved overlay', (
    WidgetTester tester,
  ) async {
    final Map<String, dynamic> map = {
      'type': 'AdaptiveCard',
      'body': [
        {
          'type': 'Input.ChoiceSet',
          'id': 'myChoice',
          'style': 'expanded',
          'choices': [
            {'title': 'Choice 1', 'value': '1'},
            {'title': 'Choice 2', 'value': '2'},
          ],
        },
      ],
    };

    await tester.pumpWidget(
      getTestWidgetFromMap(
        map: map,
        title: 'initData choice overlay',
        initData: const {'myChoice': '2'},
      ),
    );
    await tester.pumpAndSettle();

    final choiceMap = map['body'][0] as Map<String, dynamic>;
    final inputFinder = find.byKey(
      generateWidgetKey(choiceMap, suffix: 'Choice 2'),
    );
    final container = _documentContainer(tester, inputFinder);

    expect(
      container.read(resolvedElementProvider('myChoice'))?['value'],
      '2',
    );

    final Map<String, dynamic> out = {};
    tester
        .state<AdaptiveChoiceSetState>(find.byType(AdaptiveChoiceSet))
        .appendInput(out);
    expect(out['myChoice'], '2');
  });

  testWidgets('initData ignores unknown ids without creating overlays', (
    WidgetTester tester,
  ) async {
    final Map<String, dynamic> map = {
      'type': 'AdaptiveCard',
      'body': [
        {
          'type': 'Input.Text',
          'id': 'known',
        },
      ],
    };

    await tester.pumpWidget(
      getTestWidgetFromMap(
        map: map,
        title: 'initData unknown id',
        initData: const {'unknownId': 'value'},
      ),
    );
    await tester.pumpAndSettle();

    final textMap = map['body'][0] as Map<String, dynamic>;
    final container = _documentContainer(
      tester,
      find.byKey(generateWidgetKey(textMap)),
    );
    final doc = container.read(adaptiveCardDocumentProvider);

    expect(doc.overlaysById.containsKey('unknownId'), isFalse);
  });

  testWidgets('programmatic initInput updates resolved overlay after mount', (
    WidgetTester tester,
  ) async {
    final Map<String, dynamic> map = {
      'type': 'AdaptiveCard',
      'body': [
        {
          'type': 'Input.Text',
          'id': 'lateText',
          'label': 'Late',
        },
      ],
    };

    await tester.pumpWidget(
      getTestWidgetFromMap(map: map, title: 'programmatic initInput'),
    );
    await tester.pumpAndSettle();

    _cardState(tester).initInput({'lateText': 'late bound'});
    await tester.pumpAndSettle();

    final textMap = map['body'][0] as Map<String, dynamic>;
    final inputFinder = find.byKey(generateWidgetKey(textMap));
    final container = _documentContainer(tester, inputFinder);

    expect(
      container.read(resolvedElementProvider('lateText'))?['value'],
      'late bound',
    );

    final field = tester.widget<TextFormField>(inputFinder);
    expect(field.controller!.text, 'late bound');
  });

  testWidgets('initData patch map seeds choices via applyUpdatesFromMap', (
    WidgetTester tester,
  ) async {
    final Map<String, dynamic> map = {
      'type': 'AdaptiveCard',
      'body': [
        {
          'type': 'Input.ChoiceSet',
          'id': 'myChoice',
          'style': 'expanded',
          'choices': [
            {'title': 'Old', 'value': 'old'},
          ],
        },
      ],
    };

    await tester.pumpWidget(
      getTestWidgetFromMap(
        map: map,
        title: 'initData patch map',
        initData: {
          'myChoice': {
            'choices': [
              {'title': 'New', 'value': 'new'},
            ],
            'value': 'new',
          },
        },
      ),
    );
    await tester.pumpAndSettle();

    final choiceMap = map['body'][0] as Map<String, dynamic>;
    final container = _documentContainer(
      tester,
      find.byKey(generateWidgetKey(choiceMap, suffix: 'New')),
    );

    expect(
      container.read(resolvedElementProvider('myChoice'))?['value'],
      'new',
    );
    expect(
      container.read(resolvedElementProvider('myChoice'))?['choices'],
      [
        {'title': 'New', 'value': 'new'},
      ],
    );
  });

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

  testWidgets('initInput then applyUpdates enrich without conflict', (
    WidgetTester tester,
  ) async {
    final Map<String, dynamic> map = {
      'type': 'AdaptiveCard',
      'body': [
        {
          'type': 'Input.Text',
          'id': 'email',
        },
        {
          'type': 'TextBlock',
          'id': 'status',
          'text': 'Loading',
        },
      ],
    };

    await tester.pumpWidget(
      getTestWidgetFromMap(map: map, title: 'initInput applyUpdates'),
    );
    await tester.pumpAndSettle();

    _cardState(tester).initInput({'email': 'user@example.com'});
    await tester.pumpAndSettle();

    _cardState(tester).applyUpdatesFromMap({
      'status': {'text': 'Ready'},
    });
    await tester.pumpAndSettle();

    final textMap = map['body'][0] as Map<String, dynamic>;
    final container = _documentContainer(
      tester,
      find.byKey(generateWidgetKey(textMap)),
    );

    expect(
      container.read(resolvedElementProvider('email'))?['value'],
      'user@example.com',
    );
    expect(
      container.read(resolvedElementProvider('status'))?['text'],
      'Ready',
    );
  });
}
