import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/flutter_adaptive_cards.dart';
import 'package:flutter_adaptive_cards/src/elements/text_block.dart';
import 'package:flutter_adaptive_cards/src/flutter_raw_adaptive_card.dart';
import 'package:flutter_test/flutter_test.dart';

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

    final Widget widget = MaterialApp(
      home: RawAdaptiveCard.fromMap(
        map: cardMap,
        hostConfig: HostConfig(),
      ),
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

    // Change visibility to true
    // ignore: cascade_invocations
    thing2State.setIsVisible(visible: true);
    await tester.pumpAndSettle();

    // Verify both texts are now visible
    expect(find.text('thing1'), findsOneWidget);
    expect(find.text('thing2'), findsOneWidget);

    // Change thing2 visibility back to false
    thing2State.setIsVisible(visible: false);
    await tester.pumpAndSettle();

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

    final Widget widget = MaterialApp(
      home: RawAdaptiveCard.fromMap(
        map: cardMap,
        hostConfig: HostConfig(),
      ),
    );

    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    // Verify both elements are visible initially
    expect(find.text('Element 1'), findsOneWidget);
    expect(find.text('Element 2'), findsOneWidget);

    // Get the RawAdaptiveCardState
    final rawAdaptiveCardFinder = find.byType(RawAdaptiveCard);
    expect(rawAdaptiveCardFinder, findsOneWidget);

    final RawAdaptiveCardState cardState = tester.state<RawAdaptiveCardState>(
      rawAdaptiveCardFinder,
    );

    // Hide element2 using RawAdaptiveCardState.setIsVisible
    // ignore: cascade_invocations
    cardState.setIsVisible(id: 'element2', isVisible: false);
    await tester.pumpAndSettle();

    // Verify element1 is still visible and element2 is hidden
    expect(find.text('Element 1'), findsOneWidget);
    expect(find.text('Element 2'), findsNothing);

    // Show element2 again
    cardState.setIsVisible(id: 'element2', isVisible: true);
    await tester.pumpAndSettle();

    // Verify both elements are visible again
    expect(find.text('Element 1'), findsOneWidget);
    expect(find.text('Element 2'), findsOneWidget);

    // Hide element1
    cardState.setIsVisible(id: 'element1', isVisible: false);
    await tester.pumpAndSettle();

    // Verify element1 is hidden and element2 is still visible
    expect(find.text('Element 1'), findsNothing);
    expect(find.text('Element 2'), findsOneWidget);
  });

  testWidgets(
    'RawAdaptiveCardState.toggleVisibility can toggle element visibility',
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

      final Widget widget = MaterialApp(
        home: RawAdaptiveCard.fromMap(
          map: cardMap,
          hostConfig: HostConfig(),
        ),
      );

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Verify initial state: toggle1 visible, toggle2 hidden
      expect(find.text('Toggle Element 1'), findsOneWidget);
      expect(find.text('Toggle Element 2'), findsNothing);

      // Get the RawAdaptiveCardState
      final rawAdaptiveCardFinder = find.byType(RawAdaptiveCard);
      expect(rawAdaptiveCardFinder, findsOneWidget);

      final RawAdaptiveCardState cardState = tester.state<RawAdaptiveCardState>(
        rawAdaptiveCardFinder,
      );

      // Toggle toggle1 (should hide it)
      // clearer for test
      // ignore: cascade_invocations
      cardState.toggleVisibility(id: 'toggle1');
      await tester.pumpAndSettle();

      // Verify toggle1 is now hidden, toggle2 still hidden
      expect(find.text('Toggle Element 1'), findsNothing);
      expect(find.text('Toggle Element 2'), findsNothing);

      // Toggle toggle2 (should show it)
      cardState.toggleVisibility(id: 'toggle2');
      await tester.pumpAndSettle();

      // Verify toggle1 still hidden, toggle2 now visible
      expect(find.text('Toggle Element 1'), findsNothing);
      expect(find.text('Toggle Element 2'), findsOneWidget);

      // Toggle toggle1 again (should show it)
      cardState.toggleVisibility(id: 'toggle1');
      await tester.pumpAndSettle();

      // Verify both are now visible
      expect(find.text('Toggle Element 1'), findsOneWidget);
      expect(find.text('Toggle Element 2'), findsOneWidget);

      // Toggle toggle2 again (should hide it)
      cardState.toggleVisibility(id: 'toggle2');
      await tester.pumpAndSettle();

      // Verify toggle1 visible, toggle2 hidden
      expect(find.text('Toggle Element 1'), findsOneWidget);
      expect(find.text('Toggle Element 2'), findsNothing);
    },
  );
}
