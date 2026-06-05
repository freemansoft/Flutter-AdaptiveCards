import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/flutter_raw_adaptive_card.dart';
import 'package:flutter_adaptive_cards_fs/src/models/adaptive_card_update.dart';
import 'package:flutter_adaptive_cards_fs/src/riverpod/providers.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

const Map<String, dynamic> _submitAction = {
  'type': 'Action.Submit',
  'id': 'submit',
  'title': 'Send',
  'tooltip': 'Submit the form',
};

RawAdaptiveCardState _cardState(WidgetTester tester) {
  return tester.state<RawAdaptiveCardState>(find.byType(RawAdaptiveCard));
}

Finder _actionButtonFinder() {
  return find.descendant(
    of: find.byKey(generateAdaptiveWidgetKey(_submitAction)),
    matching: find.byType(ElevatedButton),
  );
}

void main() {
  testWidgets('applyUpdates updates action title and tooltip in UI', (
    WidgetTester tester,
  ) async {
    final map = <String, dynamic>{
      'type': 'AdaptiveCard',
      'body': [
        {
          'type': 'TextBlock',
          'text': 'Form',
        },
      ],
      'actions': [_submitAction],
    };

    await tester.pumpWidget(
      getTestWidgetFromMap(map: map, title: 'action title tooltip overlay'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Send'), findsOneWidget);

    _cardState(tester).applyUpdates(
      actions: const [
        AdaptiveActionUpdate(
          id: 'submit',
          title: 'Submit now',
          tooltip: 'Send it',
        ),
      ],
    );
    await tester.pump();

    expect(find.text('Submit now'), findsOneWidget);
    expect(find.text('Send'), findsNothing);

    final container = ProviderScope.containerOf(
      tester.element(_actionButtonFinder()),
    );
    expect(
      container.read(resolvedActionProvider('submit'))?['title'],
      'Submit now',
    );
    expect(
      container.read(resolvedActionProvider('submit'))?['tooltip'],
      'Send it',
    );
  });

  testWidgets('applyUpdatesFromMap patches action title by id', (
    WidgetTester tester,
  ) async {
    final map = <String, dynamic>{
      'type': 'AdaptiveCard',
      // cause its a test and I don't care
      // ignore: inference_failure_on_collection_literal
      'body': [],
      'actions': [_submitAction],
    };

    await tester.pumpWidget(
      getTestWidgetFromMap(map: map, title: 'action title from map'),
    );
    await tester.pumpAndSettle();

    _cardState(tester).applyUpdatesFromMap({
      'submit': {'title': 'Go'},
    });
    await tester.pump();

    expect(find.text('Go'), findsOneWidget);
  });
}
