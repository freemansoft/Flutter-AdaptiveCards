import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'utils/test_utils.dart';

void main() {
  testWidgets('Golden Icon', (tester) async {
    configureTestView();
    const ValueKey key = ValueKey('paint');
    final Widget sample = getSampleForGoldenTest(key, 'v1.5/icon_demo');
    await tester.pumpWidget(sample);
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(key),
      matchesGoldenFile(getGoldenPath('v1_5_icon_demo.png')),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }, tags: ['golden']);

  testWidgets('Icon catalog golden — expanded names', (tester) async {
    configureTestView(size: const Size(420, 120));
    const ValueKey key = ValueKey('paint');
    await tester.pumpWidget(getSampleForGoldenTest(key, 'v1.6/icon_catalog'));
    await tester.pumpAndSettle();
    await expectLater(
      find.byKey(key),
      matchesGoldenFile(getGoldenPath('v1_6_icon_catalog.png')),
    );
  }, tags: ['golden']);
}
