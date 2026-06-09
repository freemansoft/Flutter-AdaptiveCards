import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

void main() {
  testWidgets(
    'manual refresh affordance invokes onRefresh with verb and inputs',
    (
      tester,
    ) async {
      RefreshActionInvoke? captured;

      const card = {
        'type': 'AdaptiveCard',
        'version': '1.4',
        'refresh': {
          'action': {
            'type': 'Action.Execute',
            'verb': 'refreshCard',
            'data': {'source': 'refresh'},
          },
        },
        'body': [
          {
            'type': 'Input.Text',
            'id': 'note',
            'value': 'hello',
          },
          {
            'type': 'TextBlock',
            'text': 'Refresh demo',
          },
        ],
      };

      await tester.pumpWidget(
        getTestWidgetFromMap(
          map: card,
          title: 'refresh manual test',
          onOpenUrl: (_) {},
          onSubmit: (_) {},
          onExecute: (_) {},
          onRefresh: (invoke) => captured = invoke,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();

      expect(captured, isNotNull);
      expect(captured!.verb, 'refreshCard');
      expect(captured!.data['source'], 'refresh');
      expect(captured!.data['note'], 'hello');
    },
  );

  testWidgets('onRefresh falls back to onExecute when onRefresh is null', (
    tester,
  ) async {
    ExecuteActionInvoke? captured;

    const card = {
      'type': 'AdaptiveCard',
      'version': '1.4',
      'refresh': {
        'action': {
          'type': 'Action.Execute',
          'verb': 'refreshCard',
        },
      },
      'body': [
        {
          'type': 'TextBlock',
          'text': 'Refresh fallback',
        },
      ],
    };

    await tester.pumpWidget(
      getTestWidgetFromMap(
        map: card,
        title: 'refresh fallback test',
        onOpenUrl: (_) {},
        onSubmit: (_) {},
        onExecute: (invoke) => captured = invoke,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pumpAndSettle();

    expect(captured, isNotNull);
    expect(captured!.verb, 'refreshCard');
  });

  testWidgets('expired refresh auto-fires once on first frame', (tester) async {
    RefreshActionInvoke? captured;

    final card = {
      'type': 'AdaptiveCard',
      'version': '1.4',
      'refresh': {
        'action': {
          'type': 'Action.Execute',
          'verb': 'refreshCard',
        },
        'expires': DateTime.now()
            .subtract(const Duration(hours: 1))
            .toUtc()
            .toIso8601String(),
      },
      'body': [
        {
          'type': 'TextBlock',
          'text': 'Expired card',
        },
      ],
    };

    await tester.pumpWidget(
      getTestWidgetFromMap(
        map: card,
        title: 'refresh expire test',
        onOpenUrl: (_) {},
        onSubmit: (_) {},
        onExecute: (_) {},
        onRefresh: (invoke) => captured = invoke,
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(captured, isNotNull);
    expect(captured!.verb, 'refreshCard');
  });

  testWidgets('userIds gate auto refresh but manual refresh still works', (
    tester,
  ) async {
    RefreshActionInvoke? autoCaptured;
    var manualCount = 0;

    final card = {
      'type': 'AdaptiveCard',
      'version': '1.4',
      'refresh': {
        'action': {
          'type': 'Action.Execute',
          'verb': 'refreshCard',
        },
        'userIds': ['user-1'],
        'expires': DateTime.now()
            .subtract(const Duration(hours: 1))
            .toUtc()
            .toIso8601String(),
      },
      'body': [
        {
          'type': 'TextBlock',
          'text': 'User gated refresh',
        },
      ],
    };

    await tester.pumpWidget(
      getTestWidgetFromMap(
        map: card,
        title: 'refresh userIds test',
        currentUserId: 'other-user',
        onOpenUrl: (_) {},
        onSubmit: (_) {},
        onExecute: (_) {},
        onRefresh: (invoke) {
          autoCaptured = invoke;
          manualCount++;
        },
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(autoCaptured, isNull);

    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pumpAndSettle();

    expect(manualCount, 1);
  });

  testWidgets('userIds allows auto refresh when currentUserId matches', (
    tester,
  ) async {
    RefreshActionInvoke? captured;

    final card = {
      'type': 'AdaptiveCard',
      'version': '1.4',
      'refresh': {
        'action': {
          'type': 'Action.Execute',
          'verb': 'refreshCard',
        },
        'userIds': ['user-1'],
        'expires': DateTime.now()
            .subtract(const Duration(hours: 1))
            .toUtc()
            .toIso8601String(),
      },
      'body': [
        {
          'type': 'TextBlock',
          'text': 'Allowed auto refresh',
        },
      ],
    };

    await tester.pumpWidget(
      getTestWidgetFromMap(
        map: card,
        title: 'refresh allowed user test',
        currentUserId: 'user-1',
        onOpenUrl: (_) {},
        onSubmit: (_) {},
        onExecute: (_) {},
        onRefresh: (invoke) => captured = invoke,
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(captured, isNotNull);
    expect(captured!.verb, 'refreshCard');
  });
}
