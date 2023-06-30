import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/flutter_adaptive_cards.dart';

import '../brightness_switch.dart';

class RenderTimePage extends StatefulWidget {
  @override
  _RenderTimePageState createState() => _RenderTimePageState();
}

class _RenderTimePageState extends State<RenderTimePage> {
  Map<String, dynamic> content;

  @override
  void initState() {
    List body = [];
    int body_repeats = 1000;

    for (int i = 0; i < body_repeats; i++) {
      body.add({
        "type": "ColumnSet",
        "columns": [
          {
            "type": "Column",
            "width": "auto",
            "items": [
              {
                "type": "TextBlock",
                "text": "$i.",
              }
            ]
          },
          {
            "type": "Column",
            "items": [
              {
                "type": "TextBlock",
                "weight": "Bolder",
                "text": "$i aaaaaaaaaaaaaaaaaaaaa",
                "wrap": true
              },
              {
                "type": "TextBlock",
                "spacing": "None",
                "text": "$i bbbbbbbbbbbbbbbbbbbb",
                "isSubtle": true,
                "wrap": true
              }
            ],
            "width": "stretch"
          }
        ]
      });
    }

    content = {"type": "AdaptiveCard", "blocks": body_repeats, "body": body};

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Render Time (ListView sized:" +
            content['blocks'].toString() +
            ")"),
        actions: [
          BrightnessSwitch(),
        ],
      ),
      body: Container(
        alignment: Alignment.centerLeft,
        child: AdaptiveCard.memory(
          content: content,
          hostConfigPath: "lib/host_config",
          showDebugJson: false,
          listView: true,
          approximateDarkThemeColors: true,
          supportMarkdown: false,
        ),
      ),
    );
  }
}
