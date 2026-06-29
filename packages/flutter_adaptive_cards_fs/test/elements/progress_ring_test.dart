import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

Map<String, dynamic> _card(Map<String, dynamic> ring) => {
  'type': 'AdaptiveCard',
  'version': '1.6',
  'body': [ring],
};

CircularProgressIndicator _ring(WidgetTester tester) => tester
    .widget<CircularProgressIndicator>(find.byType(CircularProgressIndicator));

void main() {
  testWidgets('determinate value maps 0-100 to a 0.0-1.0 fraction', (
    tester,
  ) async {
    await tester.pumpWidget(
      getTestWidgetFromMap(
        map: _card({'type': 'ProgressRing', 'id': 'r', 'value': 25}),
        title: 'progress ring determinate',
      ),
    );
    await tester.pumpAndSettle();

    expect(_ring(tester).value, 0.25);
  });

  testWidgets('missing value renders an indeterminate ring', (tester) async {
    await tester.pumpWidget(
      getTestWidgetFromMap(
        map: _card({'type': 'ProgressRing', 'id': 'r'}),
        title: 'progress ring indeterminate',
      ),
    );
    // Indeterminate indicators animate forever, so settle is not an option.
    await tester.pump();

    expect(_ring(tester).value, isNull);
  });

  testWidgets('renders a caption when label is provided', (tester) async {
    await tester.pumpWidget(
      getTestWidgetFromMap(
        map: _card({
          'type': 'ProgressRing',
          'id': 'r',
          'value': 50,
          'label': 'Loading',
        }),
        title: 'progress ring label',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Loading'), findsOneWidget);
  });

  testWidgets('labelPosition below places the ring above the label', (
    tester,
  ) async {
    await tester.pumpWidget(
      getTestWidgetFromMap(
        map: _card({
          'type': 'ProgressRing',
          'id': 'r',
          'value': 50,
          'label': 'Loading',
          'labelPosition': 'Below',
        }),
        title: 'progress ring below',
      ),
    );
    await tester.pumpAndSettle();

    final ringY = tester.getCenter(find.byType(CircularProgressIndicator)).dy;
    final labelY = tester.getCenter(find.text('Loading')).dy;
    expect(ringY, lessThan(labelY));
  });

  testWidgets('labelPosition right places the ring left of the label', (
    tester,
  ) async {
    await tester.pumpWidget(
      getTestWidgetFromMap(
        map: _card({
          'type': 'ProgressRing',
          'id': 'r',
          'value': 50,
          'label': 'Loading',
          'labelPosition': 'Right',
        }),
        title: 'progress ring right',
      ),
    );
    await tester.pumpAndSettle();

    final ringX = tester.getCenter(find.byType(CircularProgressIndicator)).dx;
    final labelX = tester.getCenter(find.text('Loading')).dx;
    expect(ringX, lessThan(labelX));
  });
}
