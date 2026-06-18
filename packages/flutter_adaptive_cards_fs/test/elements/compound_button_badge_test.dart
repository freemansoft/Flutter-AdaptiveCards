import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

void main() {
  testWidgets('CompoundButton renders its badge label', (tester) async {
    final card = <String, dynamic>{
      'type': 'AdaptiveCard',
      'version': '1.5',
      'body': <Map<String, dynamic>>[
        {
          'type': 'CompoundButton',
          'title': 'Inbox',
          'description': 'Your mail',
          'badge': '3',
        },
      ],
    };
    await tester.pumpWidget(getTestWidgetFromMap(map: card, title: 'cb'));
    await tester.pump();

    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('CompoundButton without badge renders no badge', (tester) async {
    final card = <String, dynamic>{
      'type': 'AdaptiveCard',
      'version': '1.5',
      'body': <Map<String, dynamic>>[
        {'type': 'CompoundButton', 'title': 'Inbox'},
      ],
    };
    await tester.pumpWidget(getTestWidgetFromMap(map: card, title: 'cb2'));
    await tester.pump();

    expect(find.text('Inbox'), findsOneWidget);
    // No stray badge text.
    expect(find.text('3'), findsNothing);
  });
}
