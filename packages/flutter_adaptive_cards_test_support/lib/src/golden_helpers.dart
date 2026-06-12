import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_adaptive_cards_test_support/src/test_widget_helpers.dart';
import 'package:flutter_test/flutter_test.dart';

/// Configures the test view to a fixed size for golden image tests.
void configureTestView({Size size = const Size(500, 700)}) {
  RendererBinding.instance.renderViews.first.configuration =
      TestViewConfiguration.fromView(
        size: size,
        view: PlatformDispatcher.instance.implicitView!,
      );
}

/// Platform-scoped golden path under [goldFilesDirectory] (OS subdirectory) for
/// stable cross-platform baselines.
String getGoldenPath(
  String filename, {
  String goldFilesDirectory = 'gold_files',
}) {
  return '$goldFilesDirectory/${Platform.operatingSystem.toLowerCase()}/$filename';
}

/// Loads a v1.6 sample JSON fixture for golden tests.
Widget getV16SampleForGoldenTest(
  Key key,
  String sampleName, {
  String samplesDirectory = 'test/samples',
}) {
  return getTestWidgetFromPath(
    path: 'v1.6/$sampleName.json',
    key: key,
    samplesDirectory: samplesDirectory,
  );
}

/// Loads a sample JSON fixture relative to [samplesDirectory] for golden tests.
Widget getSampleForGoldenTest(
  Key key,
  String samplePath, {
  String samplesDirectory = 'test/samples',
}) {
  final path = samplePath.endsWith('.json') ? samplePath : '$samplePath.json';
  return getTestWidgetFromPath(
    path: path,
    key: key,
    samplesDirectory: samplesDirectory,
  );
}
