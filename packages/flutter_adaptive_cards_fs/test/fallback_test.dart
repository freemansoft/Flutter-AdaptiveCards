import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'utils/test_utils.dart';

void main() {
  testWidgets('fallback: drop hides the element', (WidgetTester tester) async {
    final map = {
      'type': 'AdaptiveCard',
      'version': '1.3',
      'body': [
        {'type': 'TextBlock', 'text': 'Normal Text'},
        {'type': 'UnknownFutureElement', 'fallback': 'drop'},
        {
          'type': 'AnotherUnknownElement',
          'fallback': {'type': 'TextBlock', 'text': 'Fallback Text'},
        },
      ],
    };

    final Widget widget = getTestWidgetFromMap(
      map: map,
      title: 'Fallback Test',
      listView: false,
    );
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    // Should find the normal text
    expect(find.text('Normal Text'), findsOneWidget);

    // Should NOT find the 'Adaptive_Unknown' error box because it dropped
    expect(find.textContaining('Adaptive_Unknown'), findsNothing);

    // Should find the text from the map fallback
    expect(find.text('Fallback Text'), findsOneWidget);
  });
}
