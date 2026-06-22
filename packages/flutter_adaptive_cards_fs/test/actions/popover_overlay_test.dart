import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/cards/actions/popover.dart';
import 'package:flutter_adaptive_cards_fs/src/flutter_raw_adaptive_card.dart';
import 'package:flutter_adaptive_cards_fs/src/models/adaptive_card_update.dart';
import 'package:flutter_adaptive_cards_fs/src/riverpod/providers.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

const Map<String, dynamic> _popoverAction = {
  'type': 'Action.Popover',
  'id': 'popover',
  'title': 'Show Popover',
  'tooltip': 'Open popover',
  'card': {
    'type': 'AdaptiveCard',
    'body': [
      {'type': 'TextBlock', 'text': 'Popover content'},
    ],
  },
};

RawAdaptiveCardState _cardState(WidgetTester tester) {
  return tester.state<RawAdaptiveCardState>(find.byType(RawAdaptiveCard));
}

Finder _actionButtonFinder() {
  return find.descendant(
    of: find.byKey(generateAdaptiveWidgetKey(_popoverAction)),
    matching: find.byType(ElevatedButton),
  );
}

ElevatedButton _elevatedButton(WidgetTester tester) {
  return tester.widget<ElevatedButton>(_actionButtonFinder());
}

void main() {
  testWidgets('applyUpdates updates popover action title and tooltip in UI', (
    WidgetTester tester,
  ) async {
    final map = <String, dynamic>{
      'type': 'AdaptiveCard',
      'body': [
        {'type': 'TextBlock', 'text': 'Form'},
      ],
      'actions': [_popoverAction],
    };

    await tester.pumpWidget(
      getTestWidgetFromMap(map: map, title: 'popover title tooltip overlay'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Show Popover'), findsOneWidget);

    _cardState(tester).applyUpdates(
      actions: const [
        AdaptiveActionUpdate(
          id: 'popover',
          title: 'Open menu',
          tooltip: 'Tap to open',
        ),
      ],
    );
    await tester.pump();

    expect(find.text('Open menu'), findsOneWidget);
    expect(find.text('Show Popover'), findsNothing);

    final container = ProviderScope.containerOf(
      tester.element(_actionButtonFinder()),
    );
    expect(
      container.read(resolvedActionProvider('popover'))?['title'],
      'Open menu',
    );
    expect(
      container.read(resolvedActionProvider('popover'))?['tooltip'],
      'Tap to open',
    );
  });

  testWidgets('enabled popover opens dialog on tap', (
    WidgetTester tester,
  ) async {
    final map = <String, dynamic>{
      'type': 'AdaptiveCard',
      'body': [
        {'type': 'TextBlock', 'text': 'Form'},
      ],
      'actions': [_popoverAction],
    };

    await tester.pumpWidget(
      getTestWidgetFromMap(map: map, title: 'popover enabled tap'),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AdaptivePopoverContainer), findsNothing);

    await tester.tap(_actionButtonFinder());
    await tester.pumpAndSettle();

    expect(find.byType(AdaptivePopoverContainer), findsOneWidget);
    expect(find.text('Popover content'), findsOneWidget);
  });

  testWidgets('setActionEnabled blocks popover dialog when disabled', (
    WidgetTester tester,
  ) async {
    final map = <String, dynamic>{
      'type': 'AdaptiveCard',
      'body': [
        {'type': 'TextBlock', 'text': 'Form'},
      ],
      'actions': [_popoverAction],
    };

    await tester.pumpWidget(
      getTestWidgetFromMap(map: map, title: 'popover disabled tap'),
    );
    await tester.pumpAndSettle();

    _cardState(tester).setActionEnabled('popover', enabled: false);
    await tester.pump();

    expect(_elevatedButton(tester).onPressed, isNull);

    await tester.tap(_actionButtonFinder());
    await tester.pumpAndSettle();

    expect(find.byType(AdaptivePopoverContainer), findsNothing);
    expect(find.text('Popover content'), findsNothing);

    _cardState(tester).setActionEnabled('popover', enabled: true);
    await tester.pump();

    expect(_elevatedButton(tester).onPressed, isNotNull);

    await tester.tap(_actionButtonFinder());
    await tester.pumpAndSettle();

    expect(find.byType(AdaptivePopoverContainer), findsOneWidget);
    expect(find.text('Popover content'), findsOneWidget);
  });
}
