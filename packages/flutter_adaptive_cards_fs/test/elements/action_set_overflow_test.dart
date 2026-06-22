import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

void main() {
  testWidgets('secondary-mode action is hidden until the overflow is opened', (
    WidgetTester tester,
  ) async {
    final card = <String, dynamic>{
      'type': 'AdaptiveCard',
      'version': '1.5',
      'body': <dynamic>[],
      'actions': <dynamic>[
        {'type': 'Action.Submit', 'title': 'Primary'},
        {'type': 'Action.Submit', 'title': 'Hidden', 'mode': 'secondary'},
      ],
    };

    await tester.pumpWidget(
      getTestWidgetFromMap(map: card, title: 'overflow'),
    );
    await tester.pump();

    // Primary inline; secondary not shown until overflow opened.
    expect(find.text('Primary'), findsOneWidget);
    expect(find.text('Hidden'), findsNothing);

    final overflowButton = find.byKey(const Key('action_set_overflow'));
    expect(overflowButton, findsOneWidget);

    await tester.tap(overflowButton);
    await tester.pumpAndSettle();

    expect(find.text('Hidden'), findsOneWidget);
  });

  testWidgets('with no secondary actions there is no overflow button', (
    WidgetTester tester,
  ) async {
    final card = <String, dynamic>{
      'type': 'AdaptiveCard',
      'version': '1.5',
      'body': <dynamic>[],
      'actions': <dynamic>[
        {'type': 'Action.Submit', 'title': 'Only'},
      ],
    };

    await tester.pumpWidget(
      getTestWidgetFromMap(map: card, title: 'no overflow'),
    );
    await tester.pump();

    expect(find.text('Only'), findsOneWidget);
    expect(find.byKey(const Key('action_set_overflow')), findsNothing);
  });

  testWidgets('ActionSet body element routes secondary action to overflow', (
    WidgetTester tester,
  ) async {
    final card = <String, dynamic>{
      'type': 'AdaptiveCard',
      'version': '1.5',
      'body': <dynamic>[
        {
          'type': 'ActionSet',
          'actions': <dynamic>[
            {'type': 'Action.Submit', 'title': 'SetPrimary'},
            {
              'type': 'Action.Submit',
              'title': 'SetHidden',
              'mode': 'secondary',
            },
          ],
        },
      ],
    };

    await tester.pumpWidget(
      getTestWidgetFromMap(map: card, title: 'actionset overflow'),
    );
    await tester.pump();

    expect(find.text('SetPrimary'), findsOneWidget);
    expect(find.text('SetHidden'), findsNothing);

    await tester.tap(find.byKey(const Key('action_set_overflow')));
    await tester.pumpAndSettle();

    expect(find.text('SetHidden'), findsOneWidget);
  });
}
