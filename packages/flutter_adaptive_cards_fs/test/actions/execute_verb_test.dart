import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

void main() {
  testWidgets('Action.Execute forwards verb and action id to onExecute', (
    tester,
  ) async {
    ExecuteActionInvoke? captured;

    const card = {
      'type': 'AdaptiveCard',
      'version': '1.4',
      'body': [
        {
          'type': 'Input.Text',
          'id': 'firstName',
          'value': 'Ada',
        },
      ],
      'actions': [
        {
          'type': 'Action.Execute',
          'id': 'exec-1',
          'title': 'Run',
          'verb': 'accepted',
          'data': {'x': 13},
        },
      ],
    };

    await tester.pumpWidget(
      getTestWidgetFromMap(
        map: card,
        title: 'execute invoke test',
        onOpenUrl: (_) {},
        onSubmit: (_) {},
        onExecute: (invoke) => captured = invoke,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Run'));
    await tester.pumpAndSettle();

    expect(captured, isNotNull);
    expect(captured!.verb, 'accepted');
    expect(captured!.actionId, 'exec-1');
    expect(captured!.data['x'], 13);
    expect(captured!.data['firstName'], 'Ada');
  });

  testWidgets('Action.Execute without verb passes null verb', (tester) async {
    ExecuteActionInvoke? captured;

    const card = {
      'type': 'AdaptiveCard',
      'version': '1.4',
      'body': <Map<String, dynamic>>[],
      'actions': [
        {
          'type': 'Action.Execute',
          'title': 'Run',
          'data': {'only': 'data'},
        },
      ],
    };

    await tester.pumpWidget(
      getTestWidgetFromMap(
        map: card,
        title: 'execute invoke test',
        onOpenUrl: (_) {},
        onSubmit: (_) {},
        onExecute: (invoke) => captured = invoke,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Run'));
    await tester.pumpAndSettle();

    expect(captured!.verb, isNull);
    expect(captured!.actionId, isNull);
    expect(captured!.data['only'], 'data');
  });

  testWidgets(
    'Action.Execute with associatedInputs none excludes inputs from data',
    (tester) async {
      ExecuteActionInvoke? captured;

      const card = {
        'type': 'AdaptiveCard',
        'version': '1.4',
        'body': [
          {
            'type': 'Input.Text',
            'id': 'email',
            'value': 'secret@x.com',
          },
        ],
        'actions': [
          {
            'type': 'Action.Execute',
            'title': 'Run',
            'verb': 'accepted',
            'associatedInputs': 'none',
            'data': {'actionOnly': true},
          },
        ],
      };

      await tester.pumpWidget(
        getTestWidgetFromMap(
          map: card,
          title: 'execute associatedInputs none',
          onOpenUrl: (_) {},
          onSubmit: (_) {},
          onExecute: (invoke) => captured = invoke,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Run'));
      await tester.pumpAndSettle();

      expect(captured, isNotNull);
      expect(captured!.data, {'actionOnly': true});
      expect(captured!.data.containsKey('email'), isFalse);
    },
  );
}
