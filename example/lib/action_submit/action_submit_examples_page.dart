import 'package:example/loading_adaptive_card.dart';
import 'package:flutter/material.dart';

import '../brightness_switch.dart';

class ActionSubmitPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Action.Submit"),
        actions: [
          BrightnessSwitch(),
        ],
      ),
      body: ListView(
        children: <Widget>[
          DemoAdaptiveCard("lib/action_submit/example1"),
        ],
      ),
    );
  }
}
