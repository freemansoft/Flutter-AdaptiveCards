import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'utils/test_utils.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  setUpAll(() async {
    HttpOverrides.global = MyTestHttpOverrides();

    final fontData = File('assets/fonts/Roboto/Roboto-Regular.ttf')
        .readAsBytes()
        .then((bytes) => ByteData.view(Uint8List.fromList(bytes).buffer));
    final fontData2 = File('assets/fonts/Roboto/Roboto-Bold.ttf')
        .readAsBytes()
        .then((bytes) => ByteData.view(Uint8List.fromList(bytes).buffer));
    final fontData3 = File('assets/fonts/Roboto/Roboto-Light.ttf')
        .readAsBytes()
        .then((bytes) => ByteData.view(Uint8List.fromList(bytes).buffer));
    final fontData4 = File('assets/fonts/Roboto/Roboto-Medium.ttf')
        .readAsBytes()
        .then((bytes) => ByteData.view(Uint8List.fromList(bytes).buffer));
    final fontData5 = File('assets/fonts/Roboto/Roboto-Thin.ttf')
        .readAsBytes()
        .then((bytes) => ByteData.view(Uint8List.fromList(bytes).buffer));
    final fontLoader = FontLoader('Roboto')
      ..addFont(fontData)
      ..addFont(fontData2)
      ..addFont(fontData3)
      ..addFont(fontData4)
      ..addFont(fontData5);
    await fontLoader.load();
  });

  await testMain();
}
