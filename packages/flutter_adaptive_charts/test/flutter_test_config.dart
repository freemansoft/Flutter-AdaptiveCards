import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'utils/test_utils.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  setUpAll(() async {
    HttpOverrides.global = MyTestHttpOverrides();

    final fontData1 = File('assets/fonts/Roboto/Roboto-Regular.ttf')
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

    final fontData21 = File('assets/fonts/Roboto/RobotoMono-Regular.ttf')
        .readAsBytes()
        .then((bytes) => ByteData.view(Uint8List.fromList(bytes).buffer));
    final fontData22 = File('assets/fonts/Roboto/RobotoMono-Bold.ttf')
        .readAsBytes()
        .then((bytes) => ByteData.view(Uint8List.fromList(bytes).buffer));
    final fontData23 = File('assets/fonts/Roboto/RobotoMono-Light.ttf')
        .readAsBytes()
        .then((bytes) => ByteData.view(Uint8List.fromList(bytes).buffer));
    final fontData24 = File('assets/fonts/Roboto/RobotoMono-Medium.ttf')
        .readAsBytes()
        .then((bytes) => ByteData.view(Uint8List.fromList(bytes).buffer));
    final fontData25 = File('assets/fonts/Roboto/RobotoMono-Thin.ttf')
        .readAsBytes()
        .then((bytes) => ByteData.view(Uint8List.fromList(bytes).buffer));

    final fontLoaderRoboto = FontLoader('Roboto')
      ..addFont(fontData1)
      ..addFont(fontData2)
      ..addFont(fontData3)
      ..addFont(fontData4)
      ..addFont(fontData5)
      ..addFont(fontData21)
      ..addFont(fontData22)
      ..addFont(fontData23)
      ..addFont(fontData24)
      ..addFont(fontData25);

    await fontLoaderRoboto.load();

    // Load Material Icons font for the reviews component
    // but it doesn't seem to have all the icons
    // final fontLoaderMaterialIconData =
    //     File('assets/fonts/material_fonts/MaterialIcons-Regular.ttf')
    //         .readAsBytes()
    //         .then((bytes) => ByteData.view(Uint8List.fromList(bytes).buffer));
    // final fontLoaderMaterialIcon = FontLoader('MaterialIcons')
    //   ..addFont(fontLoaderMaterialIconData);

    // await fontLoaderMaterialIcon.load();

    // final fontDataMSO =
    //     File(
    //       'assets/fonts/material_symbols_outlined/MaterialSymbolsOutlined-VariableFont_FILL,GRAD,opsz,wght.ttf',
    //     ).readAsBytes().then(
    //       (bytes) => ByteData.view(Uint8List.fromList(bytes).buffer),
    //     );
    // final fontLoaderMSO = FontLoader('MaterialSymbolsOutlined')
    //   ..addFont(
    //     fontDataMSO,
    //   );
    // await fontLoaderMSO.load();
  });

  await testMain();
}
