import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

void main() {
  testWidgets('Action.OpenUrl forwards url and actionId to onOpenUrl', (
    tester,
  ) async {
    OpenUrlActionInvoke? captured;

    const card = {
      'type': 'AdaptiveCard',
      'version': '1.0',
      'body': [],
      'actions': [
        {
          'type': 'Action.OpenUrl',
          'id': 'open-1',
          'title': 'Visit',
          'url': 'https://example.com',
        },
      ],
    };

    await tester.pumpWidget(
      getTestWidgetFromMap(
        map: card,
        title: 'open url invoke test',
        onOpenUrl: (invoke) => captured = invoke,
        onSubmit: (_) {},
        onExecute: (_) {},
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Visit'));
    await tester.pumpAndSettle();

    expect(captured, isNotNull);
    expect(captured!.actionId, 'open-1');
    expect(captured!.url, 'https://example.com');
  });

  testWidgets('Action.OpenUrl without id passes null actionId', (tester) async {
    OpenUrlActionInvoke? captured;

    const card = {
      'type': 'AdaptiveCard',
      'version': '1.0',
      'body': [],
      'actions': [
        {
          'type': 'Action.OpenUrl',
          'title': 'Visit',
          'url': 'https://example.com/no-id',
        },
      ],
    };

    await tester.pumpWidget(
      getTestWidgetFromMap(
        map: card,
        title: 'open url invoke test',
        onOpenUrl: (invoke) => captured = invoke,
        onSubmit: (_) {},
        onExecute: (_) {},
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Visit'));
    await tester.pumpAndSettle();

    expect(captured!.actionId, isNull);
    expect(captured!.url, 'https://example.com/no-id');
  });
}
