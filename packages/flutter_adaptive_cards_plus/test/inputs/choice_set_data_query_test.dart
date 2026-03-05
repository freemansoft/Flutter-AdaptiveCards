import 'package:flutter_adaptive_cards_plus/src/flutter_raw_adaptive_card.dart';
import 'package:flutter_adaptive_cards_plus/src/models/data_query.dart';
import 'package:flutter_adaptive_cards_plus/src/utils/utils.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

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
      onChange:
          (
            String id,
            dynamic value,
            DataQuery? dataQuery,
            RawAdaptiveCardState cardState,
          ) {
            selectedId = id;
            selectedValue = value;
            capturedDataQuery = dataQuery;
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
      onChange:
          (
            String id,
            dynamic value,
            DataQuery? dataQuery,
            RawAdaptiveCardState cardState,
          ) {
            selectedId = id;
            selectedValue = value;
            capturedDataQuery = dataQuery;
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
        onChange:
            (
              String id,
              dynamic value,
              DataQuery? dataQuery,
              RawAdaptiveCardState cardState,
            ) {
              selectedId = id;
              selectedValue = value;
              capturedDataQuery = dataQuery;
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
}
