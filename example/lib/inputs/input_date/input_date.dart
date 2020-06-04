import 'package:example/loading_adaptive_card.dart';
import 'package:flutter/material.dart';

import '../../brightness_switch.dart';

class InputDatePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Input.Date"),
        actions: [
          BrightnessSwitch(),
        ],
      ),
      body: ListView(
        children: <Widget>[
          DemoAdaptiveCard("lib/inputs/input_date/example1"),
        ],
      ),
    );
  }
}
