import 'dart:developer' as developer;
import 'package:format/format.dart';

import 'package:flutter/material.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter_adaptive_cards/flutter_adaptive_cards.dart';
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    ThemeMode themeMode = ThemeMode.system;
    late FlexScheme usedScheme = FlexScheme.deepBlue;
    // we know this prebuilt scheme exists exists in this map...
    // ignore: unused_local_variable
    late FlexSchemeData usedSchemeData =
        FlexColor.schemes[usedScheme] as FlexSchemeData;

    return MaterialApp(
      title: 'Flutter Demo',
      theme: FlexThemeData.light(scheme: usedScheme),
      darkTheme: FlexThemeData.dark(scheme: usedScheme),
      // Use dark or light theme based on system setting.
      themeMode: themeMode,
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        // We're not using DemoAdaptieCard() here so add our own onXXX handlers
        child: AdaptiveCard.asset(
          // loads from the assets directory in the project
          assetPath: 'lib/test_data/easy_card.json',
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
          onOpenUrl: (url) {
            developer.log(
              format('onOpenUrl url: {}', url),
              name: runtimeType.toString(),
            );
            launchUrl(Uri.parse(url));
          },
          // TODO fix this commented out code around CardRegistry
          // cardRegistry: CardRegistry(addedActions: {
          //   "Action.Submit": (map, widgetState, card) =>
          //       AdaptiveActionSubmit(map, widgetState)
          // }),
        ),
      ),
    );
  }
}
