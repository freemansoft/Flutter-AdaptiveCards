import 'package:example/loading_adaptive_card.dart';
import 'package:flutter/material.dart';

import '../../brightness_switch.dart';

class InputTimePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Input.Time"),
        actions: [
          BrightnessSwitch(),
        ],
      ),
      body: ListView(
        children: <Widget>[
          DemoAdaptiveCard("lib/inputs/input_time/example1"),
          DemoAdaptiveCard("lib/inputs/input_time/example2"),
        ],
      ),
    );
  }
}
