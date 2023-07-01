import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/flutter_adaptive_cards.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:example/brightness_switch.dart';

///
/// Similar to GenericListPage but operates against a **single** URL and not a list of resources
///
class NetworkPage extends StatelessWidget {
  final String title;
  final String url;

  NetworkPage({Key key, this.title, this.url}); // todo: add required here

  ///
  /// Will get error if no title passed "a non-null String must be provided to a Text widget."
  ///
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(this.title),
        actions: [
          BrightnessSwitch(),
        ],
      ),
      body: ListView(
        children: <Widget>[
          AdaptiveCard.network(
            // placeholder:
            //     Container(child: Center(child: CircularProgressIndicator())),
            url: this.url,
            hostConfigPath: 'assets/host_config.json',
            onSubmit: (map) {
              print(map);
              // Send to server or handle locally
            },
            onOpenUrl: (url) {
              launchUrl(Uri.parse(url));
            },
            showDebugJson: true, // enable debug in the example app
            approximateDarkThemeColors: true,
          )
        ],
      ),
    );
  }
}