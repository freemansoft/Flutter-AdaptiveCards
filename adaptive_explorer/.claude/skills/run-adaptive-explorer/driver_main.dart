// Self-capturing launch target for adaptive_explorer.
//
// WHY THIS EXISTS
// ---------------
// The normal entrypoint (lib/main.dart) boots to an empty "Select a template
// to view" screen and needs a NATIVE file-open dialog to show anything — no
// agent can drive that. AdaptiveExplorerApp exposes an `initialTemplateJson`
// seam (added for tests); this target uses it to boot with the editor already
// populated.
//
// Capturing a desktop window with macOS `screencapture` needs Screen Recording
// permission, which a sandboxed/headless shell does not have. So instead this
// target captures ITSELF from inside the running app: it wraps the app in a
// RepaintBoundary and, one second after first paint, rasterises that boundary
// to a PNG via dart:ui + dart:io. No OS permission, works headless.
//
// Run from the adaptive_explorer/ directory:
//   SCREENSHOT_OUT=/tmp/ae.png fvm flutter run -d macos \
//     -t .claude/skills/run-adaptive-explorer/driver_main.dart
//
// When SCREENSHOT_OUT is set, the app prints `SCREENSHOT_WRITTEN: <path>` once
// the PNG is on disk; drive.sh waits for that line, then quits the app.
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:adaptive_explorer/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

final GlobalKey _captureKey = GlobalKey();

void main() {
  runApp(
    RepaintBoundary(
      key: _captureKey,
      child: const AdaptiveExplorerApp(initialTemplateJson: _sampleCard),
    ),
  );

  final wantCapture = Platform.environment['SCREENSHOT_OUT'];
  if (wantCapture != null && wantCapture.isNotEmpty) {
    // Give the widget tree a beat to lay out and paint before rasterising.
    Timer(const Duration(seconds: 1), () => unawaited(_capture()));
  }
}

Future<void> _capture() async {
  try {
    // The macOS debug build is sandboxed (DebugProfile.entitlements), so it
    // can only write inside its own container. systemTemp resolves there and
    // is still readable by the unsandboxed drive.sh, which copies it out.
    final outPath =
        '${Directory.systemTemp.path}/adaptive_explorer_capture.png';
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

// A minimal Adaptive Card so the editor tabs have content to show.
const Map<String, dynamic> _sampleCard = <String, dynamic>{
  r'$schema': 'http://adaptivecards.io/schemas/adaptive-card.json',
  'type': 'AdaptiveCard',
  'version': '1.5',
  'body': <Map<String, dynamic>>[
    <String, dynamic>{
      'type': 'TextBlock',
      'text': 'run-adaptive-explorer driver',
      'size': 'large',
      'weight': 'bolder',
    },
    <String, dynamic>{
      'type': 'TextBlock',
      'text': 'This window was launched by driver_main.dart. The editor tabs '
          'show this card JSON; the preview pane renders once a merged card is '
          'loaded from disk.',
      'wrap': true,
    },
  ],
};
