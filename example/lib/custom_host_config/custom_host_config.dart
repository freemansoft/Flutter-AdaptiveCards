import 'package:example/loading_adaptive_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/flutter_adaptive_cards.dart';

import '../brightness_switch.dart';

class CustomHostConfigPage extends StatelessWidget {
  var hostConfig = HostConfig(
    containerStyles: ContainerStyles(
      standard: ContainerStyle(
          foregroundColors: ForegroundColors(
            standard: ForegroundColor(standard: Color(0xFF00FF00)),
          ),
          backgroundColor: Color(0x66FFFFFF)),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Custom Host Config"),
        actions: [
          BrightnessSwitch(),
        ],
      ),
      body: ListView.builder(
        itemCount: 15,
        itemBuilder: (context, index) {
          return DemoAdaptiveCard("lib/samples/example${index + 1}", hostConfig: hostConfig);
        },
      ),
    );
  }
}
