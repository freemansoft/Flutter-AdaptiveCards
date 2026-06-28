import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'utils/test_utils.dart';

void main() {
  testWidgets('Layout.Flow golden — narrow (stacks)', (tester) async {
    configureTestView(size: const Size(150, 1200));
    const ValueKey key = ValueKey('paint');

    await tester.pumpWidget(
      getSampleForGoldenTest(key, 'responsive/flow_container'),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(key),
      matchesGoldenFile(getGoldenPath('responsive_flow_narrow.png')),
    );
  }, tags: ['golden']);

  testWidgets('Layout.Flow golden — wide (wraps)', (tester) async {
    configureTestView(size: const Size(1000, 1200));
    const ValueKey key = ValueKey('paint');

    await tester.pumpWidget(
      getSampleForGoldenTest(key, 'responsive/flow_container'),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(key),
      matchesGoldenFile(getGoldenPath('responsive_flow_wide.png')),
    );
  }, tags: ['golden']);

  testWidgets('Layout.Flow column golden — narrow (stacks)', (tester) async {
    configureTestView(size: const Size(150, 1200));
    const ValueKey key = ValueKey('paint');

    await tester.pumpWidget(
      getSampleForGoldenTest(key, 'responsive/flow_column'),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(key),
      matchesGoldenFile(getGoldenPath('responsive_flow_column_narrow.png')),
    );
  }, tags: ['golden']);

  testWidgets('Layout.Flow column golden — wide (wraps)', (tester) async {
    configureTestView(size: const Size(1000, 1200));
    const ValueKey key = ValueKey('paint');

    await tester.pumpWidget(
      getSampleForGoldenTest(key, 'responsive/flow_column'),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(key),
      matchesGoldenFile(getGoldenPath('responsive_flow_column_wide.png')),
    );
  }, tags: ['golden']);
}
