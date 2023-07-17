import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/flutter_adaptive_cards.dart';

class RenderTimePage extends StatefulWidget {
  @override
  _RenderTimePageState createState() => _RenderTimePageState();
}

class _RenderTimePageState extends State<RenderTimePage> {
  Map<String, dynamic> content = Map();

  @override
  void initState() {
    List body = [];
    int bodyRepeats = 1000;

    for (int i = 0; i < bodyRepeats; i++) {
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
                "weight": "bolder",
                "text": "$i aaaaaaaaaaaaaaaaaaaaa",
                "wrap": true
              },
              {
                "type": "TextBlock",
                "spacing": "none",
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

    content = {"type": "AdaptiveCard", "blocks": bodyRepeats, "body": body};

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Render Time (ListView sized:" +
            content['blocks'].toString() +
            ")"),
      ),
      body: SingleChildScrollView(
        child: AdaptiveCard.memory(
          content: content,
          hostConfigPath: "lib/host_config",
          showDebugJson: true,
          listView: true,
          approximateDarkThemeColors: true,
          supportMarkdown: false,
        ),
      ),
    );
  }
}
