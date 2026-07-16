// Self-capturing launch target for the widgetbook sample app.
//
// WHY THIS EXISTS
// ---------------
// `flutter run` opens a window and waits forever — an agent cannot see it, and
// macOS `screencapture` needs Screen Recording permission a headless/sandboxed
// shell does not have. So this target launches the REAL WidgetbookApp wrapped
// in a RepaintBoundary and, a couple of seconds after first paint, rasterises
// that boundary to a PNG via dart:ui + dart:io — no OS permission, works
// headless.
//
// Run from the widgetbook/ directory (after build_runner has generated
// lib/main.directories.g.dart):
//   SCREENSHOT_OUT=/tmp/wb.png fvm flutter run -d macos \
//     -t .claude/skills/run-widgetbook/driver_main.dart
//
// When SCREENSHOT_OUT is set, the app prints `SCREENSHOT_WRITTEN: <path>` once
// the PNG is on disk; drive.sh waits for that line, then quits the app.
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:widgetbook_workspace/main.dart';

final GlobalKey _captureKey = GlobalKey();

void main() {
  runApp(
    RepaintBoundary(
      key: _captureKey,
      child: const WidgetbookApp(),
    ),
  );

  final wantCapture = Platform.environment['SCREENSHOT_OUT'];
  if (wantCapture != null && wantCapture.isNotEmpty) {
    // Widgetbook's shell (navigation + addons) needs a moment to settle.
    Timer(const Duration(seconds: 2), () => unawaited(_capture()));
  }
}

Future<void> _capture() async {
  try {
    // The macOS debug build is sandboxed (DebugProfile.entitlements), so it
    // can only write inside its own container. systemTemp resolves there and
    // is still readable by the unsandboxed drive.sh, which copies it out.
    final outPath = '${Directory.systemTemp.path}/widgetbook_capture.png';
    final boundary = _captureKey.currentContext!.findRenderObject()!
        as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File(outPath).writeAsBytesSync(bytes!.buffer.asUint8List());
    // print() reaches flutter run's stdout (as "flutter: …"), which drive.sh
    // greps for the marker; this throwaway driver has no logger.
    // ignore: avoid_print
    print('SCREENSHOT_WRITTEN: $outPath');
  } on Object catch (e) {
    // Surface failures on stdout too so the harness can report them.
    // ignore: avoid_print
    print('SCREENSHOT_FAILED: $e');
  }
}
