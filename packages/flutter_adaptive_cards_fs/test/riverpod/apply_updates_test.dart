import 'package:flutter_adaptive_cards_fs/src/flutter_raw_adaptive_card.dart';
import 'package:flutter_adaptive_cards_fs/src/models/adaptive_card_update.dart';
import 'package:flutter_adaptive_cards_fs/src/riverpod/providers.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

ProviderContainer _documentContainer(WidgetTester tester, Finder finder) {
  return ProviderScope.containerOf(tester.element(finder));
}

RawAdaptiveCardState _cardState(WidgetTester tester) {
  return tester.state<RawAdaptiveCardState>(find.byType(RawAdaptiveCard));
}

void main() {
  testWidgets('RawAdaptiveCardState.applyUpdates delegates to notifier', (
    WidgetTester tester,
  ) async {
    final map = <String, dynamic>{
      'type': 'AdaptiveCard',
      'body': [
        {
          'type': 'TextBlock',
          'id': 'status',
          'text': 'Baseline',
        },
      ],
    };

    await tester.pumpWidget(
      getTestWidgetFromMap(map: map, title: 'applyUpdates delegate'),
    );
    await tester.pumpAndSettle();

    _cardState(tester).applyUpdates(
      elements: const [
        AdaptiveElementUpdate(id: 'status', text: 'Patched'),
      ],
    );
    await tester.pump();

    final statusMap = map['body']![0] as Map<String, dynamic>;
    final container = _documentContainer(
      tester,
      find.byKey(generateAdaptiveWidgetKey(statusMap)),
    );
    expect(
      container.read(resolvedElementProvider('status'))?['text'],
      'Patched',
    );
  });

  testWidgets('applyUpdatesFromMap parses server-style patch payload', (
    WidgetTester tester,
  ) async {
    final map = <String, dynamic>{
      'type': 'AdaptiveCard',
      'body': [
        {
          'type': 'Input.Text',
          'id': 'email',
        },
      ],
      'actions': [
        {
          'type': 'Action.Submit',
          'id': 'submitAction',
          'title': 'Send',
        },
      ],
    };

    await tester.pumpWidget(
      getTestWidgetFromMap(map: map, title: 'applyUpdatesFromMap'),
    );
    await tester.pumpAndSettle();

    _cardState(tester).applyUpdatesFromMap({
      'email': {
        'value': 'user@example.com',
        'errorMessage': 'Invalid',
        'isInvalid': true,
      },
      'submitAction': {'isEnabled': false},
    });
    await tester.pump();

    final emailMap = map['body']![0] as Map<String, dynamic>;
    final container = _documentContainer(
      tester,
      find.byKey(generateWidgetKey(emailMap)),
    );
    expect(
      container.read(resolvedElementProvider('email'))?['value'],
      'user@example.com',
    );
    expect(
      container.read(resolvedActionProvider('submitAction'))?['isEnabled'],
      isFalse,
    );
  });
}
