import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'utils/test_utils.dart';

/// These test just validate the samples render without errors
void main() {
  // The Video player doesn't work on windows or linux
  // https://pub.dev/packages/video_player
  // PLatform doesn't have Platform.isWeb
  if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS || kIsWeb) {}

  // 15 has a video player in it
  // 16 should be testable
  for (int i = 1; i <= 14; i++) {
    testWidgets('example$i smoke test', (tester) async {
      Widget widget = getWidget(path: 'example$i.json');

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
