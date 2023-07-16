import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride;

import 'about_page.dart';
import 'network_page.dart';

///
/// This program lets you specify a local or remote adaptive card for viewing.
/// Intended to be used as  debugging jig
///
/// `flutter run lib/lab_web.dart -d chrome --web-renderer html --web-port <port>`
///
void main() {
  // this forces fuchsia on all platforms including ios
  // debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
  // Should pick up from some override maybe command line?
  debugDefaultTargetPlatformOverride = null;
  runApp(MyApp());
}

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
      home: new MyHomePage(
        title: 'Flutter Adaptive CardWeb Tester',
        aboutPage: AboutPage(
          themeMode: themeMode,
          onThemeModeChanged: (ThemeMode mode) {
            setState(() {
              themeMode = mode;
            });
          },
          flexSchemeData: FlexColor.schemes[usedScheme],
        ),
      ),
    );
  }
}

class MyHomePage extends StatelessWidget {
  MyHomePage({
    Key key,
    this.title,
    this.aboutPage,
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
      body: ListView(children: <Widget>[
        SizedBox(
          height: 32.0,
          child: Center(
            child: Text(
              "You can find samples at https://github.com/microsoft/AdaptiveCards/tree/main/samples/v1.5/Scenarios Use the raw json files.",
              style: TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        TextField(
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Paste in Adaptive card URL and Enter',
          ),
          onSubmitted: (url) {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => NetworkPage(title: url, url: url)));
          },
        ),
      ]),
    );
  }
}
