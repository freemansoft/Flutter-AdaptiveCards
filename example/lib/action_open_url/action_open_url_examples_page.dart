import 'package:example/brightness_switch.dart';
import 'package:example/loading_adaptive_card.dart';
import 'package:flutter/material.dart';

class ActionOpenUrlPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Action.OpenUrl"),
        actions: [
          BrightnessSwitch(),
        ],
      ),
      body: ListView(
        children: <Widget>[
          DemoAdaptiveCard("lib/action_open_url/example1"),
          DemoAdaptiveCard("lib/action_open_url/example2"),
        ],
      ),
    );
  }
}
