import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'utils/test_utils.dart';

void main() {
  testWidgets('Layout.AreaGrid golden — narrow (stacks)', (tester) async {
    configureTestView(size: const Size(160, 1200));
    const ValueKey key = ValueKey('paint');

    await tester.pumpWidget(
      getSampleForGoldenTest(key, 'responsive/area_grid'),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(key),
      matchesGoldenFile(getGoldenPath('area_grid_narrow.png')),
    );
  }, tags: ['golden']);

  testWidgets('Layout.AreaGrid golden — wide (grid)', (tester) async {
    configureTestView(size: const Size(1000, 1200));
    const ValueKey key = ValueKey('paint');

    await tester.pumpWidget(
      getSampleForGoldenTest(key, 'responsive/area_grid'),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(key),
      matchesGoldenFile(getGoldenPath('area_grid_wide.png')),
    );
  }, tags: ['golden']);
}
