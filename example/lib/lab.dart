import 'package:example/loading_adaptive_card.dart';
import 'package:flutter/material.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';

import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride;

import 'about_page.dart';

///
/// This program lets you specify a local or remote adaptive card for viewing.
/// Intended to be used as  debugging jig
///
/// `flutter run  --dart-define=url=lib/activity_update lib/lab.dart -d chrome --web-renderer html --web-port <port> `
///
void main() {
  // this forces fuchsia on all platforms including ios
  // debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
  // Should pick up from some override maybe command line?
  debugDefaultTargetPlatformOverride = null;
  runApp(MyApp());
}

///
/// Passed in with
/// * `--dart-define=url=lib/activity_update`
/// * `--dart-define=url=<url>`
///
const resourceUrl =
    String.fromEnvironment('url', defaultValue: 'lib/easy_card');

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  ThemeMode themeMode = ThemeMode.system;
  FlexScheme usedScheme = FlexScheme.mandyRed;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      // The Mandy red, light theme.
      theme: FlexThemeData.light(scheme: usedScheme),
      // The Mandy red, dark theme.
      darkTheme: FlexThemeData.dark(scheme: usedScheme),
      // Use dark or light theme based on system setting.
      themeMode: themeMode,
      home: MyHomePage(
          title: 'Adaptive Cards Lab',
          themeMode: themeMode,
          onThemeModeChanged: (ThemeMode mode) {
            setState(() {
              themeMode = mode;
            });
          },
          flexSchemeData: FlexColor.schemes[usedScheme]),
      routes: {
        'about': (context) => AboutPage(
              themeMode: themeMode,
              onThemeModeChanged: (ThemeMode mode) {
                setState(() {
                  themeMode = mode;
                });
              },
              flexSchemeData: FlexColor.schemes[usedScheme],
            ),
      },
    );
  }
}

class MyHomePage extends StatelessWidget {
  MyHomePage(
      {Key key,
      this.title,
      this.themeMode,
      this.onThemeModeChanged,
      this.flexSchemeData})
      : super(key: key);

  final String title;
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final FlexSchemeData flexSchemeData;

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text(title),
        actions: [
          MaterialButton(
            onPressed: () {
              Navigator.of(context).pushNamed('about');
            },
            child: Text(
              'About',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: new Center(
        child: SingleChildScrollView(child: DemoAdaptiveCard(resourceUrl)),
      ),
    );
  }
}
