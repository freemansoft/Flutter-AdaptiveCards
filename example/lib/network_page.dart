import 'dart:developer' as developer;
import 'package:format/format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/flutter_adaptive_cards.dart';
import 'package:url_launcher/url_launcher.dart';

import 'about_page.dart';

///
/// Similar to GenericListPage but operates against a **single** URL and not a list of resources
///
class NetworkPage extends StatelessWidget {
  final String title;
  final String url;
  final AboutPage aboutPage;

  NetworkPage({
    Key? key,
    required this.title,
    required this.url,
    required this.aboutPage,
  }); // todo: add required here

  ///
  /// Will get error if no title passed "a non-null String must be provided to a Text widget."
  ///
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          aboutPage.aboutButton(context),
        ],
      ),
      body: ListView(
        children: <Widget>[
          // We're not using DemoAdaptieCard() here so add our own onXXX handlers
          AdaptiveCard.network(
            url: this.url,
            hostConfigPath: 'assets/host_config.json',
            onChange: (id, value, state) {
              developer.log(format(
                  "onChange: id: {}, value: {}, state: {}", id, value, state));
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(format("onChange: id: {}, value: {}, state: {}",
                      id, value, state))));
            },
            onSubmit: (map) {
              developer.log(format("onSubmit map: {}", map.toString()));
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(format(
                      'onSubmit: No handler found for map: \n {}',
                      map.toString()))));
            },
            onOpenUrl: (url) {
              developer.log(format("onOpenUrl url: {}", url));
              launchUrl(Uri.parse(url));
            },
            showDebugJson: true, // enable debug in the example app
          )
        ],
      ),
    );
  }
}
