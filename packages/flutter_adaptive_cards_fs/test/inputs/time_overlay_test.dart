import 'package:flutter_adaptive_cards_fs/src/cards/inputs/time.dart';
import 'package:flutter_adaptive_cards_fs/src/riverpod/providers.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

ProviderContainer _documentContainer(WidgetTester tester, Finder inputFinder) {
  return ProviderScope.containerOf(tester.element(inputFinder));
}

void main() {
  testWidgets('initData seeds time overlay in resolvedElementProvider', (
    WidgetTester tester,
  ) async {
    final Map<String, dynamic> map = {
      'type': 'AdaptiveCard',
      'body': [
        {
          'type': 'Input.Time',
          'id': 'initTime',
        },
      ],
    };

    await tester.pumpWidget(
      getTestWidgetFromMap(
        map: map,
        title: 'Time initData overlay',
        initData: const {'initTime': '12:30'},
      ),
    );
    await tester.pumpAndSettle();

    final timeMap = map['body'][0] as Map<String, dynamic>;
    final inputFinder = find.byKey(generateWidgetKey(timeMap));
    final container = _documentContainer(tester, inputFinder);

    expect(
      container.read(resolvedElementProvider('initTime'))?['value'],
      '12:30',
    );

    final state = tester.state<AdaptiveTimeInputState>(
      find.byType(AdaptiveTimeInput),
    );
    final Map<String, dynamic> out = {};
    state.appendInput(out);
    expect((out['initTime'] as String).contains('12:30'), isTrue);
  });
}
