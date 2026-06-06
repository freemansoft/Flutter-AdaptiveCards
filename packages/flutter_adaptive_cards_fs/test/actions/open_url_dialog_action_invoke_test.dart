import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

void main() {
  testWidgets(
    'Action.OpenUrlDialog forwards url and actionId to onOpenUrlDialog',
    (tester) async {
      OpenUrlDialogActionInvoke? captured;

      const card = {
        'type': 'AdaptiveCard',
        'version': '1.0',
        'body': [],
        'actions': [
          {
            'type': 'Action.OpenUrlDialog',
            'id': 'dialog-1',
            'title': 'Open dialog',
            'url': 'https://example.com/dialog',
          },
        ],
      };

      await tester.pumpWidget(
        getTestWidgetFromMap(
          map: card,
          title: 'open url dialog invoke test',
          onOpenUrlDialog: (invoke) => captured = invoke,
          onSubmit: (_) {},
          onExecute: (_) {},
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open dialog'));
      await tester.pumpAndSettle();

      expect(captured, isNotNull);
      expect(captured!.actionId, 'dialog-1');
      expect(captured!.url, 'https://example.com/dialog');
    },
  );
}
