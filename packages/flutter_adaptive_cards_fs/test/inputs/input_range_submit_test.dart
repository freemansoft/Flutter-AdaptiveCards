import 'package:flutter_adaptive_cards_fs/src/riverpod/providers.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

/// Card with an initial `value` of 99, which is outside the `max: 5` bound.
/// The value is seeded in JSON so it bypasses the UI formatter and is present
/// in the document state when Submit fires.
Map<String, dynamic> _numberCardOutOfRange() => <String, dynamic>{
  'type': 'AdaptiveCard',
  'version': '1.5',
  'body': <Map<String, dynamic>>[
    {
      'type': 'Input.Number',
      'id': 'qty',
      'min': 1,
      'max': 5,
      'value': 99,
    },
  ],
  'actions': <Map<String, dynamic>>[
    {'type': 'Action.Submit', 'title': 'OK'},
  ],
};

Map<String, dynamic> _numberCardInRange() => <String, dynamic>{
  'type': 'AdaptiveCard',
  'version': '1.5',
  'body': <Map<String, dynamic>>[
    {
      'type': 'Input.Number',
      'id': 'qty',
      'min': 1,
      'max': 5,
    },
  ],
  'actions': <Map<String, dynamic>>[
    {'type': 'Action.Submit', 'title': 'OK'},
  ],
};

void main() {
  testWidgets('out-of-range number blocks Submit and marks input invalid', (
    WidgetTester tester,
  ) async {
    var submitCount = 0;

    // The card JSON seeds value=99 which is > max=5. The UI formatter would
    // block live entry of 99, but a JSON-seeded value bypasses the formatter
    // and lands directly in document state via node['value'].
    await tester.pumpWidget(
      getTestWidgetFromMap(
        map: _numberCardOutOfRange(),
        title: 'number range',
        onSubmit: (_) => submitCount++,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(submitCount, 0);

    final container = ProviderScope.containerOf(
      tester.element(find.byKey(generateWidgetKeyFromId('qty')).first),
    );
    expect(
      container.read(resolvedElementProvider('qty'))?['isInvalid'],
      isTrue,
    );
  });

  testWidgets('in-range number allows Submit', (WidgetTester tester) async {
    var submitCount = 0;

    await tester.pumpWidget(
      getTestWidgetFromMap(
        map: _numberCardInRange(),
        title: 'number range ok',
        onSubmit: (_) => submitCount++,
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(generateWidgetKeyFromId('qty')).first,
      '3',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(submitCount, 1);
  });
}
