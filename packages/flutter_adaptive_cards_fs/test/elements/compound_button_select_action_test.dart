import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

void main() {
  testWidgets('CompoundButton selectAction (OpenUrl) forwards actionId and url',
      (tester) async {
    OpenUrlActionInvoke? captured;

    final Map<String, dynamic> map = {
      'type': 'AdaptiveCard',
      'version': '1.5',
      'body': <Map<String, dynamic>>[
        {
          'type': 'CompoundButton',
          'title': 'Open inbox',
          'selectAction': {
            'type': 'Action.OpenUrl',
            'id': 'cb-open',
            'url': 'https://example.com/inbox',
          },
        },
      ],
    };

    await tester.pumpWidget(
      getTestWidgetFromMap(
        map: map,
        title: 'cb-select-action',
        onOpenUrl: (invoke) => captured = invoke,
        onSubmit: (_) {},
        onExecute: (_) {},
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open inbox'));
    await tester.pumpAndSettle();

    expect(captured, isNotNull);
    expect(captured!.actionId, 'cb-open');
    expect(captured!.url, 'https://example.com/inbox');
  });

  testWidgets('CompoundButton without selectAction renders disabled',
      (tester) async {
    final card = <String, dynamic>{
      'type': 'AdaptiveCard',
      'version': '1.5',
      'body': <Map<String, dynamic>>[
        {'type': 'CompoundButton', 'title': 'Inert'},
      ],
    };

    await tester.pumpWidget(
      getTestWidgetFromMap(map: card, title: 'cb-no-action'),
    );
    await tester.pumpAndSettle();

    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNull);
    expect(button.enabled, isFalse);
  });
}
