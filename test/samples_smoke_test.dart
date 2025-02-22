import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'utils/test_utils.dart';

void main() {
  // Deliver actual images
  setUp(() {
    HttpOverrides.global = MyTestHttpOverrides();
  });

  for (int i = 1; i <= 16; i++) {
    testWidgets('example$i smoke test', (tester) async {
      Widget widget = getWidget('example$i');

      // This ones pretty big, we need to wrap in in a scrollable
      if (i == 8) {
        widget = SingleChildScrollView(child: IntrinsicHeight(child: widget));
      }
      await tester.pumpWidget(widget);
      await tester.pump(
        const Duration(seconds: 1),
      ); // skip past any activity or animation
    });
  }
}
