import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/flutter_raw_adaptive_card.dart';
import 'package:flutter_adaptive_cards_fs/src/riverpod/providers.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

const Map<String, dynamic> _enabledAction = {
  'type': 'Action.Submit',
  'id': 'submitEnabled',
  'title': 'Enabled Submit',
};

const Map<String, dynamic> _disabledAction = {
  'type': 'Action.Submit',
  'id': 'submitDisabled',
  'title': 'Disabled Submit',
  'isEnabled': false,
};

ElevatedButton _elevatedButtonUnderAction(
  WidgetTester tester,
  Map<String, dynamic> actionMap,
) {
  final actionFinder = find.byKey(generateAdaptiveWidgetKey(actionMap));
  final buttonFinder = find.descendant(
    of: actionFinder,
    matching: find.byType(ElevatedButton),
  );
  return tester.widget<ElevatedButton>(buttonFinder);
}

Finder _actionButtonFinder(Map<String, dynamic> actionMap) {
  return find.descendant(
    of: find.byKey(generateAdaptiveWidgetKey(actionMap)),
    matching: find.byType(ElevatedButton),
  );
}

void main() {
  testWidgets('baseline isEnabled false disables submit button', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      getTestWidgetFromPath(
        path: 'v1.5/action_is_enabled.json',
      ),
    );
    await tester.pumpAndSettle();

    expect(
      _elevatedButtonUnderAction(tester, _disabledAction).onPressed,
      isNull,
    );
    expect(
      _elevatedButtonUnderAction(tester, _enabledAction).onPressed,
      isNotNull,
    );
  });

  testWidgets('setActionEnabled toggles submit handler', (
    WidgetTester tester,
  ) async {
    var submitCount = 0;
    await tester.pumpWidget(
      getTestWidgetFromPath(
        path: 'v1.5/action_is_enabled.json',
        onSubmit: (_) => submitCount++,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(_actionButtonFinder(_disabledAction));
    await tester.pump();
    expect(submitCount, 0);

    final cardState = tester.state<RawAdaptiveCardState>(
      find.byType(RawAdaptiveCard),
    )..setActionEnabled('submitDisabled', enabled: true);
    await tester.pump();

    expect(
      _elevatedButtonUnderAction(tester, _disabledAction).onPressed,
      isNotNull,
    );

    await tester.tap(_actionButtonFinder(_disabledAction));
    await tester.pump();
    expect(submitCount, 1);

    cardState.setActionEnabled('submitEnabled', enabled: false);
    await tester.pump();
    expect(
      _elevatedButtonUnderAction(tester, _enabledAction).onPressed,
      isNull,
    );

    final container = ProviderScope.containerOf(
      tester.element(_actionButtonFinder(_enabledAction)),
    );
    expect(
      container.read(resolvedActionProvider('submitEnabled'))?['isEnabled'],
      isFalse,
    );
  });
}
