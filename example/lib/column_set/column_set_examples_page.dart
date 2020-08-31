import 'package:example/loading_adaptive_card.dart';
import 'package:flutter/material.dart';

import '../brightness_switch.dart';

class ColumnSetPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("ColumnSet"),
        actions: [
          BrightnessSwitch(),
        ],
      ),
      body: ListView(
        children: <Widget>[
          DemoAdaptiveCard("lib/column_set/example1"),
          DemoAdaptiveCard("lib/column_set/example2"),
          DemoAdaptiveCard("lib/column_set/example3"),
          DemoAdaptiveCard("lib/column_set/example4"),
          DemoAdaptiveCard("lib/column_set/example5", supportMarkdown: false),
          DemoAdaptiveCard("lib/column_set/example6", supportMarkdown: false),
          DemoAdaptiveCard("lib/column_set/example7", supportMarkdown: false),
          DemoAdaptiveCard("lib/column_set/example8", supportMarkdown: false),
          DemoAdaptiveCard("lib/column_set/example9", supportMarkdown: false),
        ],
      ),
    );
  }
}
