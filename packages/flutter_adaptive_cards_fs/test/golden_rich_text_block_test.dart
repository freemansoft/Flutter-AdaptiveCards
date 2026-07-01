import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'utils/test_utils.dart';

void main() {
  testWidgets('Golden RichTextBlock', (tester) async {
    configureTestView();
    const ValueKey key = ValueKey('paint');
    final Widget sample = getSampleForGoldenTest(
      key,
      'v1.2/rich_text_block_demo',
    );
    await tester.pumpWidget(sample);
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(key),
      matchesGoldenFile(getGoldenPath('v1_2_rich_text_block_demo.png')),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }, tags: ['golden']);
}
