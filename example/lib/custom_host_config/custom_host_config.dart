import 'package:example/loading_adaptive_card.dart';
import 'package:flutter/material.dart';

import '../about_page.dart';

class DynamicHostConfigPage extends StatelessWidget {
  final AboutPage aboutPage;

  DynamicHostConfigPage({
    Key? key,
    required this.aboutPage,
  }); // todo: add required here

  @override
  Widget build(BuildContext context) {
    var isLight = Theme.of(context).brightness == Brightness.light;
    var defaultForegroundColor = isLight ? "FF0000" : "00FF00";

    var hostConfig = '''
  {
    "choiceSetInputValueSeparator": ",",
    "supportsInteractivity": true,
    "spacing": {
      "none": 0,
      "small": 3,
      "default": 8,
      "medium": 20,
      "large": 30,
      "extraLarge": 40,
      "padding": 10
    },
    "separator": {
      "lineThickness": 1,
      "lineColor": "#EEEEEE"
    },
    "imageSizes": {
      "small": 40,
      "medium": 80,
      "large": 160
    },
    "actions": {
      "maxActions": 5,
      "spacing": "default",
      "buttonSpacing": 10,
      "showCard": {
        "actionMode": "Inline",
        "inlineTopMargin": 16,
        "style": "emphasis"
      },
      "preExpandSingleShowCardAction": false,
      "actionsOrientation": "Vertical",
      "actionAlignment": "left"
    },
    "adaptiveCard": {
      "allowCustomStyle": false
    },
    "imageSet": {
      "imageSize": "medium",
      "maxImageHeight": 100
    },
    "factSet": {
      "title": {
        "size": "default",
        "color": "default",
        "isSubtle": false,
        "weight": "bolder",
        "warp": true
      },
      "value": {
        "size": "default",
        "color": "default",
        "isSubtle": false,
        "weight": "default",
        "warp": true
      },
      "spacing": 10
    }
  }
  ''';

    return Scaffold(
      appBar: AppBar(
        title: Text("Custom Host Config"),
        actions: [
          aboutPage.aboutButton(context),
        ],
      ),
      body: ListView.builder(
        itemCount: 15,
        itemBuilder: (context, index) {
          return Theme(
            data: ThemeData(),
            child: DemoAdaptiveCard(
              "lib/samples/example${index + 1}",
              hostConfig: hostConfig,
            ),
          );
        },
      ),
    );
  }
}
