import 'package:flutter/material.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter_adaptive_cards/flutter_adaptive_cards.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      // The Mandy red, light theme.
      theme: FlexThemeData.light(scheme: FlexScheme.mandyRed),
      // The Mandy red, dark theme.
      darkTheme: FlexThemeData.dark(scheme: FlexScheme.mandyRed),
      // Use dark or light theme based on system setting.
      themeMode: ThemeMode.system,
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatelessWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text(title),
      ),
      body: new Center(
        child: AdaptiveCard.asset(
          // loads from the assets directory in the project
          assetPath: "lib/easy_card",
          hostConfigPath: "lib/host_config",
          // TODO fix this
          // cardRegistry: CardRegistry(addedActions: {
          //   "Action.Submit": (map, widgetState, card) =>
          //       AdaptiveActionSubmit(map, widgetState, color: Colors.red)
          // }),
        ),
      ),
    );
  }
}
