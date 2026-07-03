import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'utils/test_utils.dart';

void main() {
  testWidgets('Golden authentication sign-in region', (tester) async {
    configureTestView();
    const key = ValueKey('paint');
    final sample = getSampleForGoldenTest(key, 'v1.4/authentication_signin');
    await tester.pumpWidget(sample);
    await tester.pumpAndSettle();

    await expectLater(
      find.byKey(key),
      matchesGoldenFile(getGoldenPath('v1_4_authentication_signin.png')),
    );
  }, tags: ['golden']);
}
