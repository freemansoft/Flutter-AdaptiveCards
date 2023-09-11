///
/// This is a convenience because we build so many cards in the example
///
/// Why do we need this instead of just consuming AdaptiveCard.asset ?  I have no idea
///
import 'dart:developer' as developer;
import 'package:format/format.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_adaptive_cards/flutter_adaptive_cards.dart';
import 'package:url_launcher/url_launcher.dart';

///
/// Adaptive card driven from assets and not memory or URL
///
/// This is usually the root card in the example apps.
/// We have default action behavior that will get picked up by everyone
///
/// Adds demonstration `onChange()` and `onSubmit()` handlers
///
/// * param: initData is optional and must map the schema of the cards
class DemoAdaptiveCard extends StatefulWidget {
  const DemoAdaptiveCard({
    required this.assetPath,
    Key? key,
    this.hostConfig,
    this.supportMarkdown = true,
    this.initData,
  }) : super(key: key);

  final String assetPath;
  final String? hostConfig;
  final bool supportMarkdown;

  /// This map must match the taxonomy of the page you pass in. Default to no initData.
  /// Was added to show how initData works
  final Map<String, String>? initData;

  @override
  _DemoAdaptiveCardState createState() => new _DemoAdaptiveCardState();
}

/// This exists as stateful to support the "show the JSON" function
/// Note that it means we load the JSON twice, once for this and once for the widget
class _DemoAdaptiveCardState extends State<DemoAdaptiveCard>
    with AutomaticKeepAliveClientMixin {
  String jsonFile = '{}';

  @override
  void initState() {
    super.initState();
    rootBundle.loadString(widget.assetPath).then((string) {
      jsonFile = string;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SelectionArea(
        child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: <Widget>[
          // We're not using DefaultAdaptiveCardHandlers() here so add our own onXXX() handlers
          AdaptiveCard.asset(
            assetPath: widget.assetPath,
            hostConfigPath: "lib/host_config",
            showDebugJson: true, // enable in the example app
            hostConfig: widget.hostConfig,
            supportMarkdown: widget.supportMarkdown,
            initData: widget.initData,
            onChange: (id, value, state) {
              developer.log(
                  format("onChange: id: {}, value: {}, state: {}", id, value,
                      state),
                  name: runtimeType.toString());
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(format("onChange: id: {}, value: {}, state: {}",
                      id, value, state))));
            },
            onSubmit: (map) {
              developer.log(format("onSubmit map: {}", map.toString()),
                  name: runtimeType.toString());
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(format(
                      'onSubmit: No handler found for map: \n {}',
                      map.toString()))));
            },
            onOpenUrl: (url) {
              developer.log(format("onOpenUrl url: {}", url),
                  name: runtimeType.toString());
              launchUrl(Uri.parse(url));
            },
          ),
        ],
      ),
    ));
  }

  @override
  bool get wantKeepAlive => true;
}
