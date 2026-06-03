import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/cards/elements/text_block.dart';
import 'package:flutter_adaptive_cards_fs/src/flutter_raw_adaptive_card.dart';
import 'package:flutter_adaptive_cards_fs/src/riverpod/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import '../utils/test_utils.dart';

void main() {
  testWidgets('isVisible property controls element visibility', (
    WidgetTester tester,
  ) async {
    // Create a card with two TextBlock elements
    final Map<String, dynamic> cardMap = {
      'type': 'AdaptiveCard',
      'version': '1.4',
      'body': [
        {
          'type': 'TextBlock',
          'id': 'thing1',
          'text': 'thing1',
          'isVisible': true,
        },
        {
          'type': 'TextBlock',
          'id': 'thing2',
          'text': 'thing2',
          'isVisible': false,
        },
      ],
    };

    final Widget widget = getTestWidgetFromMap(
      map: cardMap,
      title: 'Visibility Test',
    );

    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    // Verify thing1 is visible
    expect(find.text('thing1'), findsOneWidget);

    // Verify thing2 is NOT visible (should not be in widget tree)
    expect(find.text('thing2'), findsNothing);

    // Find the thing2 widget state and change its visibility
    final thing2Finder = find.byWidgetPredicate(
      (widget) => widget is AdaptiveTextBlock && widget.id == 'thing2',
    );

    expect(thing2Finder, findsOneWidget);

    final AdaptiveTextBlock thing2Widget =
        tester.widget(thing2Finder) as AdaptiveTextBlock;

    // Get the state object
    final thing2State = tester.state<AdaptiveTextBlockState>(
      find.byWidget(thing2Widget),
    );

    Future<void> setThing2Visibility({required bool visible}) async {
      thing2State.setIsVisible(visible: visible);
      await tester.pumpAndSettle();
    }

    // Change visibility to true
    await setThing2Visibility(visible: true);

    // Verify both texts are now visible
    expect(find.text('thing1'), findsOneWidget);
    expect(find.text('thing2'), findsOneWidget);

    // Change thing2 visibility back to false
    await setThing2Visibility(visible: false);

    // Verify thing2 is hidden again
    expect(find.text('thing1'), findsOneWidget);
    expect(find.text('thing2'), findsNothing);
  });

  testWidgets('RawAdaptiveCardState.setIsVisible can hide/show elements', (
    WidgetTester tester,
  ) async {
    // Create a card with two TextBlock elements
    final Map<String, dynamic> cardMap = {
      'type': 'AdaptiveCard',
      'version': '1.4',
      'body': [
        {
          'type': 'TextBlock',
          'id': 'element1',
          'text': 'Element 1',
          'isVisible': true,
        },
        {
          'type': 'TextBlock',
          'id': 'element2',
          'text': 'Element 2',
          'isVisible': true,
        },
      ],
    };

    final Widget widget = getTestWidgetFromMap(
      map: cardMap,
      title: 'RawState Visibility Test',
    );

    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    // Verify both elements are visible initially
    expect(find.text('Element 1'), findsOneWidget);
    expect(find.text('Element 2'), findsOneWidget);

    // Get the RawAdaptiveCardState
    final rawAdaptiveCardFinder = find.byType(RawAdaptiveCard);
    expect(rawAdaptiveCardFinder, findsOneWidget);

    final scopeContext = tester.element(
      find.byType(AdaptiveTextBlock).first,
    );
    final container = ProviderScope.containerOf(scopeContext);
    final notifier = container.read(adaptiveCardDocumentProvider.notifier);

    Future<void> setVisibility(String id, {required bool visible}) async {
      notifier.setVisibility(id, visible: visible);
      await tester.pumpAndSettle();
    }

    // Hide element2
    await setVisibility('element2', visible: false);

    // Verify element1 is still visible and element2 is hidden
    expect(find.text('Element 1'), findsOneWidget);
    expect(find.text('Element 2'), findsNothing);

    // Show element2 again
    await setVisibility('element2', visible: true);

    // Verify both elements are visible again
    expect(find.text('Element 1'), findsOneWidget);
    expect(find.text('Element 2'), findsOneWidget);

    // Hide element1
    await setVisibility('element1', visible: false);

    // Verify element1 is hidden and element2 is still visible
    expect(find.text('Element 1'), findsNothing);
    expect(find.text('Element 2'), findsOneWidget);
  });

  testWidgets('visibility overlay survives RawAdaptiveCard rebuild', (
    WidgetTester tester,
  ) async {
    final Map<String, dynamic> cardMap = {
      'type': 'AdaptiveCard',
      'version': '1.5',
      'body': [
        {
          'type': 'TextBlock',
          'id': 'element1',
          'text': 'Element 1',
        },
        {
          'type': 'TextBlock',
          'id': 'element2',
          'text': 'Element 2',
        },
      ],
    };

    await tester.pumpWidget(
      getTestWidgetFromMap(
        map: cardMap,
        title: 'visibility survives rebuild',
      ),
    );
    await tester.pumpAndSettle();

    final cardState = tester.state<RawAdaptiveCardState>(
      find.byType(RawAdaptiveCard),
    );
    final scopeContext = tester.element(find.byType(AdaptiveTextBlock).first);
    ProviderScope.containerOf(scopeContext)
        .read(adaptiveCardDocumentProvider.notifier)
        .setVisibility('element2', visible: false);
    await tester.pump();
    expect(find.text('Element 2'), findsNothing);

    cardState.rebuild();
    await tester.pump();

    expect(find.text('Element 1'), findsOneWidget);
    expect(find.text('Element 2'), findsNothing);
  });

  testWidgets(
    'Document notifier toggleVisibility can toggle element visibility',
    (
      WidgetTester tester,
    ) async {
      // Create a card with two TextBlock elements
      final Map<String, dynamic> cardMap = {
        'type': 'AdaptiveCard',
        'version': '1.4',
        'body': [
          {
            'type': 'TextBlock',
            'id': 'toggle1',
            'text': 'Toggle Element 1',
            'isVisible': true,
          },
          {
            'type': 'TextBlock',
            'id': 'toggle2',
            'text': 'Toggle Element 2',
            'isVisible': false,
          },
        ],
      };

      final Widget widget = getTestWidgetFromMap(
        map: cardMap,
        title: 'Toggle Visibility Test',
      );

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Verify initial state: toggle1 visible, toggle2 hidden
      expect(find.text('Toggle Element 1'), findsOneWidget);
      expect(find.text('Toggle Element 2'), findsNothing);

      // Get the RawAdaptiveCardState
      final rawAdaptiveCardFinder = find.byType(RawAdaptiveCard);
      expect(rawAdaptiveCardFinder, findsOneWidget);

      final scopeContext = tester.element(
        find.byType(AdaptiveTextBlock).first,
      );
      final container = ProviderScope.containerOf(scopeContext);
      final notifier = container.read(adaptiveCardDocumentProvider.notifier);

      Future<void> toggle(String id) async {
        notifier.toggleVisibility(id);
        await tester.pumpAndSettle();
      }

      // Toggle toggle1 (should hide it)
      await toggle('toggle1');

      // Verify toggle1 is now hidden, toggle2 still hidden
      expect(find.text('Toggle Element 1'), findsNothing);
      expect(find.text('Toggle Element 2'), findsNothing);

      // Toggle toggle2 (should show it)
      await toggle('toggle2');

      // Verify toggle1 still hidden, toggle2 now visible
      expect(find.text('Toggle Element 1'), findsNothing);
      expect(find.text('Toggle Element 2'), findsOneWidget);

      // Toggle toggle1 again (should show it)
      await toggle('toggle1');

      // Verify both are now visible
      expect(find.text('Toggle Element 1'), findsOneWidget);
      expect(find.text('Toggle Element 2'), findsOneWidget);

      // Toggle toggle2 again (should hide it)
      await toggle('toggle2');

      // Verify toggle1 visible, toggle2 hidden
      expect(find.text('Toggle Element 1'), findsOneWidget);
      expect(find.text('Toggle Element 2'), findsNothing);
    },
  );

  testWidgets('Action.ToggleVisibility toggles visibility of target elements', (
    WidgetTester tester,
  ) async {
    // Create a card with elements and an Action.ToggleVisibility action
    final Map<String, dynamic> cardMap = {
      'type': 'AdaptiveCard',
      'version': '1.4',
      'body': [
        {
          'type': 'TextBlock',
          'id': 'target1',
          'text': 'Target Element 1',
          'isVisible': true,
        },
        {
          'type': 'TextBlock',
          'id': 'target2',
          'text': 'Target Element 2',
          'isVisible': false,
        },
        {
          'type': 'TextBlock',
          'id': 'target3',
          'text': 'Target Element 3',
          'isVisible': true,
        },
      ],
      'actions': [
        {
          'type': 'Action.ToggleVisibility',
          'title': 'Toggle Elements',
          'targetElements': ['target1', 'target2'],
        },
      ],
    };

    final Widget widget = getTestWidgetFromMap(
      map: cardMap,
      title: 'Action Toggle Visibility Test',
    );

    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    // Verify initial state: target1 visible, target2 hidden, target3 visible
    expect(find.text('Target Element 1'), findsOneWidget);
    expect(find.text('Target Element 2'), findsNothing);
    expect(find.text('Target Element 3'), findsOneWidget);

    // Find and tap the ToggleVisibility action button
    final toggleButtonFinder = find.widgetWithText(
      ElevatedButton,
      'Toggle Elements',
    );
    expect(toggleButtonFinder, findsOneWidget);

    await tester.tap(toggleButtonFinder);
    await tester.pumpAndSettle();

    // After toggle: target1 should be hidden, target2 should be visible, target3 unchanged
    expect(find.text('Target Element 1'), findsNothing);
    expect(find.text('Target Element 2'), findsOneWidget);
    expect(find.text('Target Element 3'), findsOneWidget);

    // Tap again to toggle back
    await tester.tap(toggleButtonFinder);
    await tester.pumpAndSettle();

    // After second toggle: target1 visible again, target2 hidden again
    expect(find.text('Target Element 1'), findsOneWidget);
    expect(find.text('Target Element 2'), findsNothing);
    expect(find.text('Target Element 3'), findsOneWidget);
  });

  testWidgets(
    'Action.ToggleVisibility handles TargetElement objects with elementId',
    (
      WidgetTester tester,
    ) async {
      // Create a card with elements and an Action.ToggleVisibility using TargetElement objects
      final Map<String, dynamic> cardMap = {
        'type': 'AdaptiveCard',
        'version': '1.4',
        'body': [
          {
            'type': 'TextBlock',
            'id': 'elem1',
            'text': 'Element 1',
            'isVisible': true,
          },
          {
            'type': 'TextBlock',
            'id': 'elem2',
            'text': 'Element 2',
            'isVisible': false,
          },
        ],
        'actions': [
          {
            'type': 'Action.ToggleVisibility',
            'title': 'Toggle',
            'targetElements': [
              {'elementId': 'elem1'},
              {'elementId': 'elem2'},
            ],
          },
        ],
      };

      final Widget widget = getTestWidgetFromMap(
        map: cardMap,
        title: 'Target Element Visibility Test',
      );

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Verify initial state
      expect(find.text('Element 1'), findsOneWidget);
      expect(find.text('Element 2'), findsNothing);

      // Tap the toggle button
      final toggleButtonFinder = find.widgetWithText(ElevatedButton, 'Toggle');
      expect(toggleButtonFinder, findsOneWidget);

      await tester.tap(toggleButtonFinder);
      await tester.pumpAndSettle();

      // After toggle: both should be toggled
      expect(find.text('Element 1'), findsNothing);
      expect(find.text('Element 2'), findsOneWidget);
    },
  );
}
