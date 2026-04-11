import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';
import 'package:flutter_adaptive_cards_fs/src/cards/elements/text_block.dart';
import 'package:flutter_adaptive_cards_fs/src/flutter_raw_adaptive_card.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Container respects verticalContentAlignment', (
    WidgetTester tester,
  ) async {
    final map = {
      'type': 'AdaptiveCard',
      'version': '1.3',
      'body': [
        {
          'type': 'Container',
          'verticalContentAlignment': 'center',
          'items': [
            {'type': 'TextBlock', 'text': 'Centered Text'},
          ],
        },
      ],
    };

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RawAdaptiveCard.fromMap(
            map: map,
            hostConfigs: HostConfigs(),
            listView: true,
          ),
        ),
      ),
    );

    // Verify it parsed and built
    expect(find.text('Centered Text'), findsOneWidget);

    // Find the Column that wraps the items
    final columnFinder = find.byWidgetPredicate(
      (widget) =>
          widget is Column &&
          widget.children.any((c) => c is AdaptiveTextBlock),
    );
    expect(columnFinder, findsOneWidget);

    final Column column = tester.widget<Column>(columnFinder);
    expect(column.mainAxisAlignment, equals(MainAxisAlignment.center));
  });
}
