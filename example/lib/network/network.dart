import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/flutter_adaptive_cards.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:example/brightness_switch.dart';

class NetworkPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Network Remote URL'),
        actions: [
          BrightnessSwitch(),
        ],
      ),
      body: ListView(
        children: <Widget>[
          AdaptiveCard.network(
            // placeholder:
            //     Container(child: Center(child: CircularProgressIndicator())),
            url:
                'https://raw.githubusercontent.com/microsoft/AdaptiveCards/main/samples/v1.5/Scenarios/ExpenseReport.json',
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

/*
 * This is a total hack that existed in the rep prior to 6/2023
 * Really these should be stateful with passed in context but it is just an example
 */
class NetworkAssetsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Network deployed Assets'),
        actions: [
          BrightnessSwitch(),
        ],
      ),
      body: ListView(
        children: <Widget>[
          AdaptiveCard.network(
            // placeholder:
            //     Container(child: Center(child: CircularProgressIndicator())),
            url: 'assets/ac-qv-faqs.json',
            hostConfigPath: 'assets/host_config.json',
            // TODO: Templating would be more powerful
            // TODO: This is hardcoded against the card schema
            initData: {
              'fullname': 'minato',
              'bookingdate': '08/05/2023',
              'gender': 'female'
            },
            onChange: (id, key, cardState) {
              // TODO: This is hard coded against the card schema and should be AdaptiveCard driven
              print('$id - $key');
              // Department options choices vary based on the selected gender
              if (id == 'gender') {
                if (key == 'male')
                  cardState.loadInput('department', {'1': '1'});
                else
                  cardState.loadInput('department', {'2': '2', '3': '3'});
              }
            },
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
