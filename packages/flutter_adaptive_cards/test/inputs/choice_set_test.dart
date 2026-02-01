import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/flutter_adaptive_cards.dart';
import 'package:flutter_adaptive_cards/src/flutter_raw_adaptive_card.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AdaptiveChoiceSet expanded single select (Radio buttons)', (
    WidgetTester tester,
  ) async {
    String? selectedValue;

    final Map<String, dynamic> map = {
      'type': 'AdaptiveCard',
      'body': [
        {
          'type': 'Input.ChoiceSet',
          'id': 'myChoiceSet',
          'style': 'expanded',
          'choices': [
            {'title': 'Choice 1', 'value': '1'},
            {'title': 'Choice 2', 'value': '2'},
          ],
        },
      ],
    };

    final Widget widget = MaterialApp(
      home: Scaffold(
        body: RawAdaptiveCard.fromMap(
          map: map,
          hostConfigs: HostConfigs(),
          onChange: (id, value, state) {
            if (id == 'myChoiceSet') {
              selectedValue = value as String?;
            }
          },
        ),
      ),
    );

    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    // Find the RadioListTiles
    final choice1Finder = find.widgetWithText(
      RadioListTile<String>,
      'Choice 1',
    );
    final choice2Finder = find.widgetWithText(
      RadioListTile<String>,
      'Choice 2',
    );

    expect(choice1Finder, findsOneWidget);
    expect(choice2Finder, findsOneWidget);

    // Initial state: nothing selected

    // Tap Choice 2
    await tester.tap(choice2Finder);
    await tester.pump();

    // Verify onChange was called with '2'
    expect(selectedValue, equals('2'));

    // Tap Choice 1
    await tester.tap(choice1Finder);
    await tester.pump();

    // Verify onChange was called with '1'
    expect(selectedValue, equals('1'));
  });

  testWidgets(
    'AdaptiveChoiceSet compact (Dropdown) has keys and selection works',
    (
      WidgetTester tester,
    ) async {
      String? selectedValue;

      final Map<String, dynamic> map = {
        'type': 'AdaptiveCard',
        'body': [
          {
            'type': 'Input.ChoiceSet',
            'id': 'myChoiceSet',
            'style': 'compact',
            'choices': [
              {'title': 'Choice 1', 'value': '1'},
              {'title': 'Choice 2', 'value': '2'},
            ],
          },
        ],
      };

      final Widget widget = MaterialApp(
        home: Scaffold(
          body: RawAdaptiveCard.fromMap(
            map: map,
            hostConfigs: HostConfigs(),
            onChange: (id, value, state) {
              if (id == 'myChoiceSet') selectedValue = value as String?;
            },
          ),
        ),
      );

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Dropdown exists and has correct key
      expect(find.byKey(const ValueKey('myChoiceSet')), findsOneWidget);

      // Open dropdown and select Choice 2
      await tester.tap(find.byKey(const ValueKey('myChoiceSet')));
      await tester.pumpAndSettle();

      // Find the menu item and tap it
      final itemFinder = find.text('Choice 2');
      expect(itemFinder, findsWidgets);
      await tester.tap(itemFinder.first);
      await tester.pumpAndSettle();

      // Verify onChange was called with the value '2'
      expect(selectedValue, equals('2'));
    },
  );

  testWidgets('AdaptiveChoiceSet expanded multi-select (Checkbox) works', (
    WidgetTester tester,
  ) async {
    String? selectedValue;

    final Map<String, dynamic> map = {
      'type': 'AdaptiveCard',
      'body': [
        {
          'type': 'Input.ChoiceSet',
          'id': 'myChoiceSet',
          'style': 'expanded',
          'isMultiSelect': true,
          'choices': [
            {'title': 'Choice 1', 'value': '1'},
            {'title': 'Choice 2', 'value': '2'},
          ],
        },
      ],
    };

    final Widget widget = MaterialApp(
      home: Scaffold(
        body: RawAdaptiveCard.fromMap(
          map: map,
          hostConfigs: HostConfigs(),
          onChange: (id, value, state) {
            if (id == 'myChoiceSet') selectedValue = value as String?;
          },
        ),
      ),
    );

    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    // Check the checkbox tile keys exist
    expect(find.byKey(const ValueKey('myChoiceSet_Choice 2')), findsOneWidget);

    // Tap the tile for Choice 2
    await tester.tap(find.byKey(const ValueKey('myChoiceSet_Choice 2')));
    await tester.pumpAndSettle();

    expect(selectedValue, equals('2'));
  });

  testWidgets('AdaptiveChoiceSet filtered opens modal and propagates inputId', (
    WidgetTester tester,
  ) async {
    String? selectedValue;

    final Map<String, dynamic> map = {
      'type': 'AdaptiveCard',
      'body': [
        {
          'type': 'Input.ChoiceSet',
          'id': 'myChoiceSet',
          'style': 'filtered',
          'choices': [
            {'title': 'Choice 1', 'value': '1'},
            {'title': 'Choice 2', 'value': '2'},
          ],
        },
      ],
    };

    final Widget widget = MaterialApp(
      home: Scaffold(
        body: RawAdaptiveCard.fromMap(
          map: map,
          hostConfigs: HostConfigs(),
          onChange: (id, value, state) {
            if (id == 'myChoiceSet') selectedValue = value as String?;
          },
        ),
      ),
    );

    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    // The filtered text field is present and keyed
    expect(find.byKey(const ValueKey('myChoiceSet')), findsOneWidget);

    // Tap to open the modal
    await tester.tap(find.byKey(const ValueKey('myChoiceSet')));
    await tester.pumpAndSettle();

    // After opening modal, the card field, the ChoiceFilter widget and the modal search field share the key
    expect(find.byKey(const ValueKey('myChoiceSet')), findsNWidgets(3));

    // The modal lists values (names) '1' and '2' — tap '2'
    final modalItem = find.text('2');
    expect(modalItem, findsWidgets);
    await tester.tap(modalItem.first);
    await tester.pumpAndSettle();

    // Filtered mode returns the choice **title** as the onChange payload (Select uses id)
    expect(selectedValue, equals('Choice 2'));
  });
}
