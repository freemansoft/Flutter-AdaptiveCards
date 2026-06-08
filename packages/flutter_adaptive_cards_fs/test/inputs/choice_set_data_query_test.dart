import 'package:flutter_adaptive_cards_fs/src/flutter_raw_adaptive_card.dart';
import 'package:flutter_adaptive_cards_fs/src/models/data_query.dart';
import 'package:flutter_adaptive_cards_fs/src/riverpod/providers.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

RawAdaptiveCardState _cardState(WidgetTester tester) {
  return tester.state<RawAdaptiveCardState>(find.byType(RawAdaptiveCard));
}

Map<String, dynamic> _dataQueryChoiceSetCard() {
  return {
    'type': 'AdaptiveCard',
    'version': '1.5',
    'body': [
      {
        'type': 'Input.ChoiceSet',
        'id': 'selectedUser',
        'placeholder': 'Search for a user...',
        'choices': [
          {'title': 'Static choice example', 'value': 'static_value'},
        ],
        'choices.data': {
          'type': 'Data.Query',
          'dataset': 'graph.microsoft.com/users',
        },
        'style': 'expanded',
      },
    ],
  };
}

void main() {
  testWidgets('Input.ChoiceSet with Data.Query passes dataQuery to onChange', (
    WidgetTester tester,
  ) async {
    String? selectedId;
    dynamic selectedValue;
    DataQuery? capturedDataQuery;

    final Map<String, dynamic> map = {
      'type': 'AdaptiveCard',
      'version': '1.5',
      'body': [
        {
          'type': 'Input.ChoiceSet',
          'id': 'selectedUser',
          'placeholder': 'Search for a user...',
          'choices': [
            {'title': 'Static choice example', 'value': 'static_value'},
          ],
          'choices.data': {
            'type': 'Data.Query',
            'dataset': 'graph.microsoft.com/users',
          },
          'style': 'expanded',
        },
      ],
    };

    final widget = getTestWidgetFromMap(
      map: map,
      title: 'Input.ChoiceSet with Data.Query passes dataQuery to onChange',
      onChange: (invoke) {
        selectedId = invoke.inputId;
        selectedValue = invoke.value;
        capturedDataQuery = invoke.dataQuery;
      },
    );

    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    final Map<String, dynamic> elementMap =
        map['body'][0] as Map<String, dynamic>;

    // Find the RadioListTile for 'Static choice example'
    final choiceFinder = find.byKey(
      generateWidgetKey(elementMap, suffix: 'Static choice example'),
    );
    expect(choiceFinder, findsOneWidget);

    // Tap the choice
    await tester.tap(choiceFinder);
    await tester.pump();

    // Verify onChange values
    expect(selectedId, equals('selectedUser'));
    expect(selectedValue, equals('static_value'));
    expect(capturedDataQuery, isNotNull);
    expect(capturedDataQuery!.dataset, equals('graph.microsoft.com/users'));
  });

  testWidgets('Input.ChoiceSet without Data.Query passes null to onChange', (
    WidgetTester tester,
  ) async {
    String? selectedId;
    dynamic selectedValue;
    DataQuery? capturedDataQuery;

    final Map<String, dynamic> map = {
      'type': 'AdaptiveCard',
      'version': '1.5',
      'body': [
        {
          'type': 'Input.ChoiceSet',
          'id': 'myChoiceSet',
          'choices': [
            {'title': 'Choice 1', 'value': '1'},
          ],
          'style': 'expanded',
        },
      ],
    };

    final widget = getTestWidgetFromMap(
      map: map,
      title: 'Input.ChoiceSet without Data.Query passes null to onChange',
      onChange: (invoke) {
        selectedId = invoke.inputId;
        selectedValue = invoke.value;
        capturedDataQuery = invoke.dataQuery;
      },
    );

    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    final Map<String, dynamic> elementMap =
        map['body'][0] as Map<String, dynamic>;

    final choiceFinder = find.byKey(
      generateWidgetKey(elementMap, suffix: 'Choice 1'),
    );
    await tester.tap(choiceFinder);
    await tester.pump();

    expect(selectedId, equals('myChoiceSet'));
    expect(selectedValue, equals('1'));
    expect(capturedDataQuery, isNull);
  });

  testWidgets(
    'Input.ChoiceSet v1.6 data_query.json passes DataQuery to onChange',
    (WidgetTester tester) async {
      String? selectedId;
      dynamic selectedValue;
      DataQuery? capturedDataQuery;

      // Load the v1.6 sample using getTestWidgetFromPath.
      // path is relative to test/samples/
      final widget = getTestWidgetFromPath(
        path: 'v1.6/data_query.json',
        onChange: (invoke) {
          selectedId = invoke.inputId;
          selectedValue = invoke.value;
          capturedDataQuery = invoke.dataQuery;
        },
      );

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      final choiceFinder1 = find.byKey(
        generateWidgetKeyFromId('selectedUser', suffix: 'Title1'),
      );
      expect(choiceFinder1, findsOneWidget);

      // The choice set id in data_query.json is 'selectedUser'.
      // The choice under test is 'Title2' with value 'value_2'.
      final choiceFinder2 = find.byKey(
        generateWidgetKeyFromId('selectedUser', suffix: 'Title2'),
      );
      expect(choiceFinder2, findsOneWidget);

      await tester.tap(choiceFinder2);
      await tester.pump();

      // Verify the onChange callback received the expected values.
      expect(selectedId, equals('selectedUser'));
      expect(selectedValue, equals('value_2'));
      expect(capturedDataQuery, isNotNull);
      expect(
        capturedDataQuery!.dataset,
        equals('graph.microsoft.com/users'),
      );
    },
  );

  testWidgets('loadInput after mount refreshes ChoiceSet with choices.data', (
    WidgetTester tester,
  ) async {
    final map = _dataQueryChoiceSetCard();
    final elementMap = map['body'][0] as Map<String, dynamic>;

    await tester.pumpWidget(
      getTestWidgetFromMap(
        map: map,
        title: 'Data.Query loadInput refresh',
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(
        generateWidgetKey(elementMap, suffix: 'Static choice example'),
      ),
      findsOneWidget,
    );

    _cardState(tester).loadInput('selectedUser', {
      'User A': 'user_a',
      'User B': 'user_b',
    });
    await tester.pumpAndSettle();

    expect(
      find.byKey(
        generateWidgetKey(elementMap, suffix: 'Static choice example'),
      ),
      findsNothing,
    );
    expect(
      find.byKey(generateWidgetKey(elementMap, suffix: 'User A')),
      findsOneWidget,
    );
    expect(
      find.byKey(generateWidgetKey(elementMap, suffix: 'User B')),
      findsOneWidget,
    );

    final container = ProviderScope.containerOf(
      tester.element(
        find.byKey(generateWidgetKey(elementMap, suffix: 'User A')),
      ),
    );
    final choices =
        container.read(resolvedElementProvider('selectedUser'))?['choices']
            as List<dynamic>?;
    expect(choices?.length, 2);
    final titles = choices!
        .map((c) => (c as Map<String, dynamic>)['title'] as String)
        .toList();
    expect(titles, containsAll(['User A', 'User B']));
  });

  testWidgets(
    'onChange with Data.Query then loadInput replaces choices in UI',
    (
      WidgetTester tester,
    ) async {
      final map = _dataQueryChoiceSetCard();
      final elementMap = map['body'][0] as Map<String, dynamic>;

      await tester.pumpWidget(
        getTestWidgetFromMap(
          map: map,
          title: 'Data.Query onChange loadInput',
          onChange: (invoke) {
            expect(invoke.dataQuery, isNotNull);
            expect(invoke.dataQuery!.dataset, 'graph.microsoft.com/users');
            invoke.cardState.loadInput(invoke.inputId, {
              'Fetched User': 'fetched_1',
            });
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(
          generateWidgetKey(elementMap, suffix: 'Static choice example'),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          generateWidgetKey(elementMap, suffix: 'Static choice example'),
        ),
        findsNothing,
      );
      expect(
        find.byKey(generateWidgetKey(elementMap, suffix: 'Fetched User')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Data.Query associatedInputs auto merges country into parameters',
    (
      WidgetTester tester,
    ) async {
      DataQuery? captured;
      final map = {
        'type': 'AdaptiveCard',
        'version': '1.5',
        'body': [
          {
            'type': 'Input.ChoiceSet',
            'id': 'country',
            'choices': [
              {'title': 'USA', 'value': 'usa'},
            ],
            'value': 'usa',
          },
          {
            'type': 'Input.ChoiceSet',
            'id': 'city',
            'choices': [
              {'title': 'NYC', 'value': 'nyc'},
            ],
            'choices.data': {
              'type': 'Data.Query',
              'dataset': 'cities',
              'associatedInputs': 'auto',
            },
            'style': 'expanded',
          },
        ],
      };

      await tester.pumpWidget(
        getTestWidgetFromMap(
          map: map,
          title: 'associatedInputs merge',
          onChange: (invoke) {
            if (invoke.inputId == 'city') captured = invoke.dataQuery;
          },
        ),
      );
      await tester.pumpAndSettle();

      final cityElementMap = (map['body']! as List)[1]! as Map<String, dynamic>;
      await tester.tap(
        find.byKey(
          generateWidgetKey(
            cityElementMap,
            suffix: 'NYC',
          ),
        ),
      );
      await tester.pump();

      expect(captured, isNotNull);
      expect(captured!.parameters?['country'], 'usa');
    },
  );

  testWidgets(
    'setDataQuerySession updates resolved choices.data count and skip',
    (WidgetTester tester) async {
      final map = _dataQueryChoiceSetCard();
      final elementMap = map['body'][0] as Map<String, dynamic>;

      await tester.pumpWidget(
        getTestWidgetFromMap(
          map: map,
          title: 'Data.Query session overlay',
        ),
      );
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(
          find.byKey(
            generateWidgetKey(elementMap, suffix: 'Static choice example'),
          ),
        ),
      );
      container
          .read(adaptiveCardDocumentProvider.notifier)
          .setDataQuerySession(
            'selectedUser',
            count: 25,
            skip: 50,
            searchText: 'alice',
          );
      await tester.pump();

      final resolved = container.read(resolvedElementProvider('selectedUser'));
      final choicesData = resolved?['choices.data'] as Map<String, dynamic>?;
      expect(choicesData?['dataset'], 'graph.microsoft.com/users');
      expect(choicesData?['count'], 25);
      expect(choicesData?['skip'], 50);
      expect(choicesData?.containsKey('searchText'), isFalse);

      final overlay = container
          .read(adaptiveCardDocumentProvider)
          .overlaysById['selectedUser'];
      expect(overlay?.querySearchText, 'alice');

      // Session-only changes do not refresh choice tiles without loadInput.
      expect(
        find.byKey(
          generateWidgetKey(elementMap, suffix: 'Static choice example'),
        ),
        findsOneWidget,
      );
    },
  );
}
