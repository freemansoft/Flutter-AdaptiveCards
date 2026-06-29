import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

Map<String, dynamic> _card(Map<String, dynamic> bar) => {
  'type': 'AdaptiveCard',
  'version': '1.6',
  'body': [bar],
};

LinearProgressIndicator _bar(WidgetTester tester) => tester
    .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator));

void main() {
  testWidgets('determinate value maps 0-100 to a 0.0-1.0 fraction', (
    tester,
  ) async {
    await tester.pumpWidget(
      getTestWidgetFromMap(
        map: _card({'type': 'ProgressBar', 'id': 'p', 'value': 50}),
        title: 'progress bar determinate',
      ),
    );
    await tester.pumpAndSettle();

    expect(_bar(tester).value, 0.5);
  });

  testWidgets('missing value renders an indeterminate bar', (tester) async {
    await tester.pumpWidget(
      getTestWidgetFromMap(
        map: _card({'type': 'ProgressBar', 'id': 'p'}),
        title: 'progress bar indeterminate',
      ),
    );
    // Indeterminate indicators animate forever, so settle is not an option.
    await tester.pump();

    expect(_bar(tester).value, isNull);
  });

  testWidgets('value above 100 clamps to full', (tester) async {
    await tester.pumpWidget(
      getTestWidgetFromMap(
        map: _card({'type': 'ProgressBar', 'id': 'p', 'value': 150}),
        title: 'progress bar clamp high',
      ),
    );
    await tester.pumpAndSettle();

    expect(_bar(tester).value, 1.0);
  });

  testWidgets('negative value clamps to empty', (tester) async {
    await tester.pumpWidget(
      getTestWidgetFromMap(
        map: _card({'type': 'ProgressBar', 'id': 'p', 'value': -10}),
        title: 'progress bar clamp low',
      ),
    );
    await tester.pumpAndSettle();

    expect(_bar(tester).value, 0.0);
  });
}
