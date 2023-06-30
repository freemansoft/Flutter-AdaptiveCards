import 'package:example/loading_adaptive_card.dart';
import 'package:flutter/material.dart';

import 'brightness_switch.dart';

class GenericListPage extends StatelessWidget {
  final String title;
  final List<String> urls;
  final List<bool> supportMarkdowns;

  // TODO: supportMarkdown should eventually be eliminated - see README.md
  GenericListPage(
      {Key key, this.title, this.urls, this.supportMarkdowns = const []})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(this.title),
        actions: [
          BrightnessSwitch(),
        ],
      ),
      body: ListView.builder(
        itemCount: this.urls.length,
        itemBuilder: (context, index) {
          if (this.supportMarkdowns.length > index + 1) {
            return DemoAdaptiveCard(urls[index],
                supportMarkdown: supportMarkdowns[index]);
          } else {
            return DemoAdaptiveCard(urls[index]);
          }
        },
      ),
    );
  }
}
