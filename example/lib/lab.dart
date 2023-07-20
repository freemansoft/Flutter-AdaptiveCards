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
  // we know mandyRed exists in this map...
  FlexSchemeData usedSchemeData =
      FlexColor.schemes[FlexScheme.mandyRed] as FlexSchemeData;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: FlexThemeData.light(scheme: usedScheme),
      darkTheme: FlexThemeData.dark(scheme: usedScheme),
      // Use dark or light theme based on system setting.
      themeMode: themeMode,
      home: MyHomePage(
        title: 'Adaptive Cards Lab',
        aboutPage: AboutPage(
          themeMode: themeMode,
          onThemeModeChanged: (ThemeMode mode) {
            setState(() {
              themeMode = mode;
            });
          },
          flexSchemeData: usedSchemeData,
        ),
      ),
    );
  }
}

class MyHomePage extends StatelessWidget {
  MyHomePage({
    Key? key,
    required this.title,
    required this.aboutPage,
  }) : super(key: key);

  final String title;
  final AboutPage aboutPage;

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: new AppBar(
          title: new Text(title),
          actions: [
            aboutPage.aboutButton(context),
          ],
        ),
        body: SelectionArea(
          child: new Center(
            child: SingleChildScrollView(child: DemoAdaptiveCard(resourceUrl)),
          ),
        ));
  }
}
