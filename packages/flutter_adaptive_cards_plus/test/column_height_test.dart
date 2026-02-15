import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'utils/test_utils.dart';

void main() {
  testWidgets('ColumnSet Size Test', (tester) async {
    final Widget widget = getTestWidgetFromPath(path: 'column_height.json');

    await tester.pumpWidget(widget);

    // Verify IntrinsicHeight IS present now
    final intrinsicHeightFinder = find.byType(IntrinsicHeight);

    // We expect this to be FOUND now
    expect(intrinsicHeightFinder, findsOneWidget);

    // We also expect CrossAxisAlignment.stretch on the Row
    final rowFinder = find.byType(Row);

    final rows = tester.widgetList<Row>(rowFinder);
    bool foundStretchAlignedRow = false;
    for (final row in rows) {
      if (row.children.length == 2 &&
          row.crossAxisAlignment == CrossAxisAlignment.stretch) {
        foundStretchAlignedRow = true;
      }
    }

    expect(
      foundStretchAlignedRow,
      isTrue,
      reason: 'Should find a Row with CrossAxisAlignment.stretch',
    );
  });
}
