import 'package:example/loading_adaptive_card.dart';
import 'package:flutter/material.dart';

import 'brightness_switch.dart';

class GenericListPage extends StatelessWidget {
  final String title;
  final List<String> urls;

  GenericListPage({Key key, this.title, this.urls});

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
          return DemoAdaptiveCard(urls[index]);
        },
      ),
    );
  }
}
