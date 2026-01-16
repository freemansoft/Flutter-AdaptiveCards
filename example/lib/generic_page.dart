import 'dart:developer' as developer;
import 'package:flutter_adaptive_cards/flutter_adaptive_cards.dart';
import 'package:format/format.dart';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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
    developer.log(
      format('URLs: {}', urls.toString()),
      // ignore: require_trailing_commas
      name: runtimeType.toString(),
    );
    return Scaffold(
      appBar: AppBar(
        leading: homeButtonIfNoHistory(context),
        title: Text(title),
        // add home button to child pages in example app so can hit reload off the home page
        actions: [aboutPage.aboutButton(context)],
      ),
      body: ListView.builder(
        itemCount: urls.length,
        itemBuilder: (context, index) {
          bool thisSupportsMarkdown;
          String url = urls[index];
          if (supportMarkdowns.length > index + 1) {
            thisSupportsMarkdown = supportMarkdowns[index];
          } else {
            thisSupportsMarkdown = true;
          }
          return SelectionArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: <Widget>[
                  // We're not using DefaultAdaptiveCardHandlers() here so add our own onXXX() handlers
                  AdaptiveCard.asset(
                    assetPath: url,
                    supportMarkdown: thisSupportsMarkdown,
                    initData: initData,
                    onChange: (id, value, state) {
                      developer.log(
                        format(
                          'onChange: id: {}, value: {}, state: {}',
                          id,
                          value,
                          state,
                        ),
                        name: runtimeType.toString(),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            format(
                              'onChange: id: {}, value: {}, state: {}',
                              id,
                              value,
                              state,
                            ),
                          ),
                        ),
                      );
                    },
                    onSubmit: (map) {
                      developer.log(
                        format('onSubmit map: {}', map.toString()),
                        name: runtimeType.toString(),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            format(
                              'onSubmit: No handler found for map: \n {}',
                              map.toString(),
                            ),
                          ),
                        ),
                      );
                    },
                    onExecute: (map) {
                      developer.log(
                        format('onExecute map: {}', map.toString()),
                        name: runtimeType.toString(),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            format(
                              'onExecute: No handler found for map: \n {}',
                              map.toString(),
                            ),
                          ),
                        ),
                      );
                    },
                    onOpenUrl: (url) {
                      developer.log(
                        format('onOpenUrl url: {}', url),
                        name: runtimeType.toString(),
                      );
                      launchUrl(Uri.parse(url));
                    },
                    showDebugJson: true, // enable debug in the example app
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
