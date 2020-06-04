import 'package:example/loading_adaptive_card.dart';
import 'package:flutter/material.dart';

import '../../brightness_switch.dart';

class InputTogglePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Input.Toggle"),
        actions: [
          BrightnessSwitch(),
        ],
      ),
      body: ListView(
        children: <Widget>[
          DemoAdaptiveCard("lib/inputs/input_toggle/example1"),
        ],
      ),
    );
  }
}
