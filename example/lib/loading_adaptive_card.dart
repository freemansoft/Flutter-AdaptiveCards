///
/// This is a convenience because we build so many cards in the example
///
/// Why do we need this instead of just consuming AdaptiveCard.asset ?  I have no idea
///
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_adaptive_cards/flutter_adaptive_cards.dart';

///
/// Adaptive card driven from assets and not memory or URL
///
class DemoAdaptiveCard extends StatefulWidget {
  const DemoAdaptiveCard(
    this.assetPath, {
    Key key,
    this.hostConfig,
    this.approximateDarkThemeColors = true,
    this.supportMarkdown = true,
  }) : super(key: key);

  final String assetPath;
  final String hostConfig;
  final bool approximateDarkThemeColors;
  final bool supportMarkdown;

  @override
  _DemoAdaptiveCardState createState() => new _DemoAdaptiveCardState();
}

/// This exists as stateful to support the "show the JSON" function
/// Note that it means we load the JSON twice, once for this and once for the widget
class _DemoAdaptiveCardState extends State<DemoAdaptiveCard>
    with AutomaticKeepAliveClientMixin {
  String jsonFile;

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
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: <Widget>[
          AdaptiveCard.asset(
            assetPath: widget.assetPath,
            hostConfigPath: "lib/host_config",
            showDebugJson: true, // enable in the example app
            hostConfig: widget.hostConfig,
            approximateDarkThemeColors: widget.approximateDarkThemeColors,
            supportMarkdown: widget.supportMarkdown,
          ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
