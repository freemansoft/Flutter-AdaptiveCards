import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

void main() {
  testWidgets('Action.Submit forwards action id and merged data to onSubmit', (
    tester,
  ) async {
    SubmitActionInvoke? captured;

    const card = {
      'type': 'AdaptiveCard',
      'version': '1.0',
      'body': [
        {
          'type': 'Input.Text',
          'id': 'firstName',
          'value': 'Ada',
        },
      ],
      'actions': [
        {
          'type': 'Action.Submit',
          'id': 'submit-1',
          'title': 'Send',
          'data': {'x': 13},
        },
      ],
    };

    await tester.pumpWidget(
      getTestWidgetFromMap(
        map: card,
        title: 'submit invoke test',
        onOpenUrl: (_) {},
        onSubmit: (invoke) => captured = invoke,
        onExecute: (_) {},
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Send'));
    await tester.pumpAndSettle();

    expect(captured, isNotNull);
    expect(captured!.actionId, 'submit-1');
    expect(captured!.data['x'], 13);
    expect(captured!.data['firstName'], 'Ada');
  });

  testWidgets('Action.Submit without id passes null actionId', (tester) async {
    SubmitActionInvoke? captured;

    const card = {
      'type': 'AdaptiveCard',
      'version': '1.0',
      'body': <Map<String, dynamic>>[],
      'actions': [
        {
          'type': 'Action.Submit',
          'title': 'Send',
          'data': {'only': 'data'},
        },
      ],
    };

    await tester.pumpWidget(
      getTestWidgetFromMap(
        map: card,
        title: 'submit invoke test',
        onOpenUrl: (_) {},
        onSubmit: (invoke) => captured = invoke,
        onExecute: (_) {},
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Send'));
    await tester.pumpAndSettle();

    expect(captured!.actionId, isNull);
    expect(captured!.data['only'], 'data');
  });

  testWidgets(
    'Action.Submit with associatedInputs none excludes inputs from data',
    (tester) async {
      SubmitActionInvoke? captured;

      const card = {
        'type': 'AdaptiveCard',
        'version': '1.0',
        'body': [
          {
            'type': 'Input.Text',
            'id': 'email',
            'value': 'secret@x.com',
          },
        ],
        'actions': [
          {
            'type': 'Action.Submit',
            'title': 'Send',
            'associatedInputs': 'none',
            'data': {'actionOnly': true},
          },
        ],
      };

      await tester.pumpWidget(
        getTestWidgetFromMap(
          map: card,
          title: 'submit associatedInputs none',
          onOpenUrl: (_) {},
          onSubmit: (invoke) => captured = invoke,
          onExecute: (_) {},
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();

      expect(captured, isNotNull);
      expect(captured!.data, {'actionOnly': true});
      expect(captured!.data.containsKey('email'), isFalse);
    },
  );
}
