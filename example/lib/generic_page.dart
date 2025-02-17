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
/// Supports accepting an initData - hack actually sends same initData to every page in list
/// Should actually pass in a list of initData, one for each url!
class GenericListPage extends StatelessWidget {
  final String title;
  final List<String> urls;
  final List<bool> supportMarkdowns;
  final AboutPage aboutPage;
  final Map<String, String> initData;

  // TODO: supportMarkdown should eventually be eliminated - see README.md
  const GenericListPage({
    super.key,
    required this.title,
    required this.urls,
    this.supportMarkdowns = const [],
    required this.aboutPage,
    this.initData = const {},
  });

  @override
  Widget build(BuildContext context) {
    developer.log(format('URLs: {}', urls.toString()),
        name: runtimeType.toString());
    return Scaffold(
      appBar: AppBar(
        leading: homeButtonIfNoHistory(context),
        title: Text(title),
        actions: [
          // add home button to child pages in example app so can hit reload off the home page
          aboutPage.aboutButton(context),
        ],
      ),
      body: ListView.builder(
        itemCount: urls.length,
        itemBuilder: (context, index) {
          if (supportMarkdowns.length > index + 1) {
            return DemoAdaptiveCard(
              assetPath: urls[index],
              supportMarkdown: supportMarkdowns[index],
              initData: initData,
            );
          } else {
            return DemoAdaptiveCard(
              assetPath: urls[index],
              initData: initData,
            );
          }
        },
      ),
    );
  }
}
