import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/src/flutter_raw_adaptive_card.dart';

class MyTestHttpOverrides extends HttpOverrides {}

Widget getWidthDefaultHostConfig(String name) {
  return getWidget(name, 'host_config');
}

Map getDefaultHostConfig() {
  var hostConfigFile = File('host_configs/host_config');
  String config = hostConfigFile.readAsStringSync();
  return json.decode(config);
}

Widget getWidget(String path, String hostConfigPath) {
  var file = File('test/samples/$path');
  var hostConfigFile = File('test/host_configs/$hostConfigPath');
  var map = json.decode(file.readAsStringSync());
  var hostConfig = json.decode(hostConfigFile.readAsStringSync());
  Widget adaptiveCard = RawAdaptiveCard.fromMap(
    map,
    hostConfig,
    //onChange: (_) {},
    onSubmit: (_) {},
    onOpenUrl: (_) {},
    // debug panels don't show in prod so dislable them in the golden images
    showDebugJson: false,
  );

  return MaterialApp(
    home: adaptiveCard,
  );
}
