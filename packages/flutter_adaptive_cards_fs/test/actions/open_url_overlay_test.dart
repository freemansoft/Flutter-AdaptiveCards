import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/flutter_raw_adaptive_card.dart';
import 'package:flutter_adaptive_cards_fs/src/riverpod/providers.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

const Map<String, dynamic> _openUrlAction = {
  'type': 'Action.OpenUrl',
  'id': 'openUrlAction',
  'title': 'Open',
  'url': 'https://example.com',
};

RawAdaptiveCardState _cardState(WidgetTester tester) =>
    tester.state<RawAdaptiveCardState>(find.byType(RawAdaptiveCard));

Finder _actionButtonFinder() {
  return find.descendant(
    of: find.byKey(generateAdaptiveWidgetKey(_openUrlAction)),
    matching: find.byType(ElevatedButton),
  );
}

void main() {
  testWidgets('setActionEnabled toggles open url handler', (
    WidgetTester tester,
  ) async {
    var openCount = 0;
    final map = <String, dynamic>{
      'type': 'AdaptiveCard',
      'body': <dynamic>[],
      'actions': [_openUrlAction],
    };

    await tester.pumpWidget(
      getTestWidgetFromMap(
        map: map,
        title: 'open url overlay isEnabled',
        onOpenUrl: (_) => openCount++,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(_actionButtonFinder());
    await tester.pump();
    expect(openCount, 1);

    _cardState(tester).setActionEnabled('openUrlAction', enabled: false);
    await tester.pump();

    expect(
      tester
          .widget<ElevatedButton>(_actionButtonFinder())
          .onPressed,
      isNull,
    );

    await tester.tap(_actionButtonFinder());
    await tester.pump();
    expect(openCount, 1);

    final container = ProviderScope.containerOf(
      tester.element(_actionButtonFinder()),
    );
    expect(
      container.read(resolvedActionProvider('openUrlAction'))?['isEnabled'],
      isFalse,
    );
  });
}
