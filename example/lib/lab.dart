import 'package:example/loading_adaptive_card.dart';
import 'package:flutter/material.dart';

import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride;

///
/// This program lets you specify a local or remote adaptive card for viewing.
/// Intended to be used as  debugging jig
///
/// `flutter run  --dart-define=url=lib/activity_update lib/lab.dart -d chrome --web-renderer html `
///
void main() {
  debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
  runApp(new MyApp());
}

const resourceUrl =
    String.fromEnvironment('url', defaultValue: 'lib/easy_card');

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Flutter Demo',
      theme: new ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: new MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key}) : super(key: key);

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text('Adpative cards lab'),
      ),
      body: new Center(
        child: SingleChildScrollView(child: DemoAdaptiveCard(resourceUrl)),
      ),
    );
  }
}
