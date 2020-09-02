import 'package:example/loading_adaptive_card.dart';
import 'package:flutter/material.dart';

import '../brightness_switch.dart';

class ImagePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Image"),
        actions: [
          BrightnessSwitch(),
        ],
      ),
      body: ListView(
        children: <Widget>[
          DemoAdaptiveCard("lib/image/example1"),
          DemoAdaptiveCard("lib/image/example2"),
          DemoAdaptiveCard("lib/image/example3"),
          DemoAdaptiveCard("lib/image/example4"),
          DemoAdaptiveCard("lib/image/example5"),
          DemoAdaptiveCard("lib/image/example6"),
          DemoAdaptiveCard("lib/image/width_and_heigh_set_in_pixels"),
          DemoAdaptiveCard("lib/image/width_set_in_pixels"),
          DemoAdaptiveCard("lib/image/height_set_in_pixels"),
        ],
      ),
    );
  }
}
