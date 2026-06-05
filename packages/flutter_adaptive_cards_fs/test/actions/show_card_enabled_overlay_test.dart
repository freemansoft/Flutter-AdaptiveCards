import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/flutter_raw_adaptive_card.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

Map<String, dynamic> _showCardActionMap() => {
  'type': 'Action.ShowCard',
  'id': 'showCardAction',
  'title': 'Expand section',
  'isEnabled': false,
  'card': {
    'type': 'AdaptiveCard',
    'version': '1.5',
    'body': [
      {
        'type': 'TextBlock',
        'id': 'expandedText',
        'text': 'Expanded content',
      },
    ],
    'actions': <Map<String, dynamic>>[],
  },
};

Map<String, dynamic> _showCardCardMap() => {
  'type': 'AdaptiveCard',
  'version': '1.5',
  'body': <Map<String, dynamic>>[],
  'actions': [_showCardActionMap()],
};

ElevatedButton _showCardButton(WidgetTester tester) {
  final actionMap = _showCardActionMap();
  final actionFinder = find.byKey(generateAdaptiveWidgetKey(actionMap));
  final buttonFinder = find.descendant(
    of: actionFinder,
    matching: find.byType(ElevatedButton),
  );
  return tester.widget<ElevatedButton>(buttonFinder);
}

void main() {
  testWidgets('baseline isEnabled false disables ShowCard button', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      getTestWidgetFromMap(
        map: _showCardCardMap(),
        title: 'ShowCard isEnabled baseline',
      ),
    );
    await tester.pumpAndSettle();

    expect(_showCardButton(tester).onPressed, isNull);
    expect(find.text('Expanded content'), findsNothing);
  });

  testWidgets('setActionEnabled toggles ShowCard expand button', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      getTestWidgetFromMap(
        map: _showCardCardMap(),
        title: 'ShowCard isEnabled overlay',
      ),
    );
    await tester.pumpAndSettle();

    final actionMap = _showCardActionMap();
    final actionFinder = find.byKey(generateAdaptiveWidgetKey(actionMap));
    final buttonFinder = find.descendant(
      of: actionFinder,
      matching: find.byType(ElevatedButton),
    );

    await tester.tap(buttonFinder);
    await tester.pump();
    expect(find.text('Expanded content'), findsNothing);

    tester
        .state<RawAdaptiveCardState>(find.byType(RawAdaptiveCard))
        .setActionEnabled('showCardAction', enabled: true);
    await tester.pump();

    expect(_showCardButton(tester).onPressed, isNotNull);

    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();

    expect(find.text('Expanded content'), findsOneWidget);
  });
}
