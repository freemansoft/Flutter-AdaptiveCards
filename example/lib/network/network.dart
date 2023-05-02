import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/flutter_adaptive_cards.dart';

import '../brightness_switch.dart';

class NetworkPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Media'),
        actions: [
          BrightnessSwitch(),
        ],
      ),
      body: ListView(
        children: <Widget>[
          AdaptiveCard.network(
            placeholder: Text('Loading, please wait'),
            url: 'assets/ac-qv-faqs.json',
            hostConfigPath: 'assets/host_config.json',
            onSubmit: (map) {
              // Send to server or handle locally
            },
            onOpenUrl: (url) {
              // Open url using the browser or handle differently
            },
            // If this is set, a button will appear next to each adaptive card which when clicked shows the payload.
            // NOTE: this will only be shown in debug mode, this attribute does change nothing for realease builds.
            // This is very useful for debugging purposes
            showDebugJson: true,
            // If you have not implemented explicit dark theme, Adaptive Cards will try to approximate its colors to match the dark theme
            // so the contrast and color meaning stays the same.
            // Turn this off, if you want to have full control over the colors when using the dark theme.
            // NOTE: This is currently still under development
            approximateDarkThemeColors: true,
          )
        ],
      ),
    );
  }
}
