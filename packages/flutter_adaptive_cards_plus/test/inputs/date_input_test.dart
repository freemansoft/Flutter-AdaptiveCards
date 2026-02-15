import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_plus/flutter_adaptive_cards.dart';
import 'package:flutter_adaptive_cards_plus/src/flutter_raw_adaptive_card.dart';
import 'package:flutter_adaptive_cards_plus/src/inputs/date.dart';
import 'package:flutter_adaptive_cards_plus/src/utils/utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('DateInput renders with correct key and label', (
    WidgetTester tester,
  ) async {
    final Map<String, dynamic> map = {
      'type': 'AdaptiveCard',
      'body': [
        {
          'type': 'Input.Date',
          'id': 'myDate',
          'label': 'Choose date',
        },
      ],
    };

    final Widget widget = MaterialApp(
      home: Scaffold(
        body: RawAdaptiveCard.fromMap(
          map: map,
          hostConfigs: HostConfigs(),
        ),
      ),
    );

    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    // adaptive card element
    expect(find.byKey(generateAdaptiveWidgetKey(map)), findsOneWidget);

    // now finds two probably label and help text
    expect(find.text('Choose date'), findsAtLeastNWidgets(1));
    expect(find.byType(AdaptiveDateInput), findsOneWidget);
    // the input.date field itself
    expect(
      find.byKey(generateAdaptiveWidgetKey(map['body'][0])),
      findsOneWidget,
    );
    expect(find.byKey(generateWidgetKey(map['body'][0])), findsOneWidget);

    expect(find.byKey(const ValueKey('myDate')), findsOneWidget);
  });

  testWidgets('DateInput initData and appendInput work', (
    WidgetTester tester,
  ) async {
    final Map<String, dynamic> map = {
      'type': 'AdaptiveCard',
      'body': [
        {
          'type': 'Input.Date',
          'id': 'initDate',
          'label': 'Init Date',
        },
      ],
    };

    final Widget widget = MaterialApp(
      home: Scaffold(
        body: RawAdaptiveCard.fromMap(
          map: map,
          initData: const {'initDate': '2024-01-02'},
          hostConfigs: HostConfigs(),
        ),
      ),
    );

    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    final TextFormField field = tester.widget(
      find.byKey(const ValueKey('initDate')),
    );

    // Controller should be formatted as yyyy-MM-dd
    expect(field.controller!.text, equals('2024-01-02'));

    final dynamic state = tester.state(find.byType(AdaptiveDateInput));
    final Map<String, dynamic> out = {};
    state.appendInput(out);
    expect((out['initDate'] as String).startsWith('2024-01-02'), isTrue);
  });
}
