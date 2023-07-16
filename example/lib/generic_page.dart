import 'dart:developer' as developer;
import 'package:format/format.dart';

import 'package:example/loading_adaptive_card.dart';
import 'package:flutter/material.dart';

import 'about_page.dart';

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
    Key key,
    this.title,
    this.urls,
    this.supportMarkdowns = const [],
    this.aboutPage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    developer.log(format("URLs: {}", urls));
    return Scaffold(
      appBar: AppBar(
        title: Text(this.title),
        actions: [
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
