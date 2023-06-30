import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/flutter_adaptive_cards.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:example/brightness_switch.dart';

class NetworkPage extends StatelessWidget {
  final String title;
  final String url;

  NetworkPage({Key key, this.title, this.url}); // todo: add required here

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
            showDebugJson: false,
            approximateDarkThemeColors: true,
          )
        ],
      ),
    );
  }
}
