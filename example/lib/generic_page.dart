import 'dart:developer' as developer;
import 'package:format/format.dart';

import 'package:example/loading_adaptive_card.dart';
import 'package:flutter/material.dart';

import 'about_page.dart';
import 'nav_support.dart';

///
/// A generic page that holds a list of AdaptiveCards based on the passed in URLs
/// Similar to NetworkPage but operates against a list of local resources
///
class GenericListPage extends StatelessWidget {
  final String title;
  final List<String> urls;
  final List<bool> supportMarkdowns;
  final AboutPage aboutPage;

  // TODO: supportMarkdown should eventually be eliminated - see README.md
  GenericListPage({
    Key? key,
    required this.title,
    required this.urls,
    this.supportMarkdowns = const [],
    required this.aboutPage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    developer.log(format("URLs: {}", urls.toString()),
        name: runtimeType.toString());
    return Scaffold(
      appBar: AppBar(
        leading: homeButtonIfNoHistory(context),
        title: Text(this.title),
        actions: [
          // add home button to child pages in example app so can hit reload off the home page
          aboutPage.aboutButton(context),
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
