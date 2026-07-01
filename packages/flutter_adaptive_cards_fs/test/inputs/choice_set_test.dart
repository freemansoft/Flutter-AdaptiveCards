import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';
import 'package:flutter_test/flutter_test.dart';
import '../utils/test_utils.dart';

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

    final Widget widget = getTestWidgetFromMap(
      map: map,
      title: 'ChoiceSet Expanded Test',
      onChange: (invoke) {
        if (invoke.inputId == 'myChoiceSet') {
          selectedValue = invoke.value as String?;
        }
      },
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

      final Widget widget = getTestWidgetFromMap(
        map: map,
        title: 'ChoiceSet Compact Test',
        onChange: (invoke) {
          if (invoke.inputId == 'myChoiceSet') {
            selectedValue = invoke.value as String?;
          }
        },
      );

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      final choiceMap = map['body'][0] as Map<String, dynamic>;
      // Dropdown exists and has correct key
      expect(find.byKey(generateWidgetKey(choiceMap)), findsOneWidget);

      // Open dropdown and select Choice 2
      await tester.tap(find.byKey(generateWidgetKey(choiceMap)));
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

  testWidgets(
    'AdaptiveChoiceSet compact supports type-ahead keyboard selection',
    (WidgetTester tester) async {
      String? selectedValue;

      final Map<String, dynamic> map = {
        'type': 'AdaptiveCard',
        'body': [
          {
            'type': 'Input.ChoiceSet',
            'id': 'myChoiceSet',
            'style': 'compact',
            'choices': [
              {'title': 'New York', 'value': 'nyc'},
              {'title': 'Los Angeles', 'value': 'la'},
            ],
          },
        ],
      };

      // Type-ahead requires the DropdownMenu to be focusable, which it is only
      // on desktop platforms (a keyboard is present). Override the platform so
      // this test exercises the keyboard path; on mobile the field is tap-only.
      // Reset inside the body (not addTearDown) so the framework's debug-var
      // invariant check, which runs before tearDowns, does not fail.
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      try {
        await tester.pumpWidget(
          getTestWidgetFromMap(
            map: map,
            title: 'ChoiceSet Compact Type-ahead Test',
            onChange: (invoke) {
              if (invoke.inputId == 'myChoiceSet') {
                selectedValue = invoke.value as String?;
              }
            },
          ),
        );
        await tester.pumpAndSettle();

        final choiceMap = map['body'][0] as Map<String, dynamic>;

        // Open the DropdownMenu, type to highlight a match, commit with Enter —
        // no tap on the menu item. Proves keyboard navigation, matching the web
        // renderer's native `<select>` behavior.
        await tester.tap(find.byKey(generateWidgetKey(choiceMap)));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField).first, 'Los Angeles');
        await tester.pumpAndSettle();

        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();

        expect(selectedValue, equals('la'));
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
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

    final Widget widget = getTestWidgetFromMap(
      map: map,
      title: 'ChoiceSet MultiSelect Test',
      onChange: (invoke) {
        if (invoke.inputId == 'myChoiceSet') {
          selectedValue = invoke.value as String?;
        }
      },
    );

    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    final choiceMap = map['body'][0] as Map<String, dynamic>;
    // Check the checkbox tile keys exist
    expect(
      find.byKey(generateWidgetKey(choiceMap, suffix: 'Choice 2')),
      findsOneWidget,
    );

    // Tap the tile for Choice 2
    await tester.tap(
      find.byKey(generateWidgetKey(choiceMap, suffix: 'Choice 2')),
    );
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

    final Widget widget = getTestWidgetFromMap(
      map: map,
      title: 'ChoiceSet Filtered Test',
      onChange: (invoke) {
        if (invoke.inputId == 'myChoiceSet') {
          selectedValue = invoke.value as String?;
        }
      },
    );

    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    final choiceMap = map['body'][0] as Map<String, dynamic>;
    // The filtered text field is present and keyed
    expect(find.byKey(generateWidgetKey(choiceMap)), findsOneWidget);

    // Tap to open the modal
    await tester.tap(find.byKey(generateWidgetKey(choiceMap)));
    await tester.pumpAndSettle();

    // After opening modal, the card field, the ChoiceFilter widget and the
    // modal search field share the key
    expect(find.byKey(generateWidgetKey(choiceMap)), findsNWidgets(3));

    // The modal lists choice titles — tap 'Choice 2'
    final modalItem = find.text('Choice 2');
    expect(modalItem, findsWidgets);
    await tester.tap(modalItem.first);
    await tester.pumpAndSettle();

    // Filtered mode returns the choice **value** as the onChange payload
    expect(selectedValue, equals('2'));
  });

  testWidgets('AdaptiveChoiceSet filtered search matches choice titles', (
    WidgetTester tester,
  ) async {
    final Map<String, dynamic> map = {
      'type': 'AdaptiveCard',
      'body': [
        {
          'type': 'Input.ChoiceSet',
          'id': 'myChoiceSet',
          'style': 'filtered',
          'choices': [
            {'title': 'New York', 'value': 'nyc'},
            {'title': 'Los Angeles', 'value': 'la'},
          ],
        },
      ],
    };

    await tester.pumpWidget(
      getTestWidgetFromMap(
        map: map,
        title: 'ChoiceSet Filtered Title Search',
      ),
    );
    await tester.pumpAndSettle();

    final choiceMap = map['body'][0] as Map<String, dynamic>;
    await tester.tap(find.byKey(generateWidgetKey(choiceMap)));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(generateWidgetKey(choiceMap)).last,
      'angeles',
    );
    await tester.pumpAndSettle();

    expect(find.text('Los Angeles'), findsOneWidget);
    expect(find.text('New York'), findsNothing);
  });

  testWidgets(
    'compact dropdown defaults to enableSearch true / requestFocusOnTap null',
    (tester) async {
      final Map<String, dynamic> map = {
        'type': 'AdaptiveCard',
        'body': [
          {
            'type': 'Input.ChoiceSet',
            'id': 'cs',
            'style': 'compact',
            'choices': [
              {'title': 'Choice 1', 'value': '1'},
            ],
          },
        ],
      };

      await tester.pumpWidget(
        getTestWidgetFromMap(map: map, title: 'ChoiceSet Default Search'),
      );
      await tester.pumpAndSettle();

      final dropdown = tester.widget<DropdownMenu<String>>(
        find.byType(DropdownMenu<String>),
      );
      expect(dropdown.enableSearch, isTrue);
      expect(dropdown.requestFocusOnTap, isNull);
    },
  );

  testWidgets(
    'compact dropdown honors HostConfig inputs.choiceSet overrides',
    (tester) async {
      final Map<String, dynamic> map = {
        'type': 'AdaptiveCard',
        'body': [
          {
            'type': 'Input.ChoiceSet',
            'id': 'cs',
            'style': 'compact',
            'choices': [
              {'title': 'Choice 1', 'value': '1'},
            ],
          },
        ],
      };

      const hostJson = {
        'inputs': {
          'choiceSet': {'enableSearch': false, 'requestFocusOnTap': true},
        },
      };
      final hostConfigs = HostConfigs(
        light: HostConfig.fromJson(hostJson),
        dark: HostConfig.fromJson(hostJson),
      );

      await tester.pumpWidget(
        getTestWidgetFromMap(
          map: map,
          title: 'ChoiceSet Search Override',
          hostConfigs: hostConfigs,
        ),
      );
      await tester.pumpAndSettle();

      final dropdown = tester.widget<DropdownMenu<String>>(
        find.byType(DropdownMenu<String>),
      );
      expect(dropdown.enableSearch, isFalse);
      expect(dropdown.requestFocusOnTap, isTrue);
    },
  );
}
