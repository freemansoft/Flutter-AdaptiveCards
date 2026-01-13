import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/src/flutter_raw_adaptive_card.dart';

class MyTestHttpOverrides extends HttpOverrides {}

Widget getWidget(String path) {
  var file = File('test/samples/$path');
  var map = json.decode(file.readAsStringSync());
  Widget adaptiveCard = RawAdaptiveCard.fromMap(
    map,
    //onChange: (_) {},
    onSubmit: (_) {},
    onExecute: (_) {},
    onOpenUrl: (_) {},
    // debug panels don't show in prod so dislable them in the golden images
    showDebugJson: false,
  );

  return MaterialApp(
    home: adaptiveCard,
  );
}
