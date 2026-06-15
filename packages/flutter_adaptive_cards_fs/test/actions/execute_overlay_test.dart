import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/flutter_raw_adaptive_card.dart';
import 'package:flutter_adaptive_cards_fs/src/riverpod/providers.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

const Map<String, dynamic> _executeAction = {
  'type': 'Action.Execute',
  'id': 'executeAction',
  'title': 'Execute',
  'verb': 'doThing',
};

Finder _actionButtonFinder() {
  return find.descendant(
    of: find.byKey(generateAdaptiveWidgetKey(_executeAction)),
    matching: find.byType(ElevatedButton),
  );
}

void main() {
  testWidgets('setActionEnabled toggles execute handler', (
    WidgetTester tester,
  ) async {
    var executeCount = 0;
    final map = <String, dynamic>{
      'type': 'AdaptiveCard',
      'body': <dynamic>[],
      'actions': [_executeAction],
    };

    await tester.pumpWidget(
      getTestWidgetFromMap(
        map: map,
        title: 'execute overlay isEnabled',
        onExecute: (_) => executeCount++,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(_actionButtonFinder());
    await tester.pump();
    expect(executeCount, 1);

    tester
        .state<RawAdaptiveCardState>(find.byType(RawAdaptiveCard))
        .setActionEnabled('executeAction', enabled: false);
    await tester.pump();

    expect(
      tester
          .widget<ElevatedButton>(_actionButtonFinder())
          .onPressed,
      isNull,
    );

    await tester.tap(_actionButtonFinder());
    await tester.pump();
    expect(executeCount, 1);

    final container = ProviderScope.containerOf(
      tester.element(_actionButtonFinder()),
    );
    expect(
      container.read(resolvedActionProvider('executeAction'))?['isEnabled'],
      isFalse,
    );
  });
}
