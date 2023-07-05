import 'package:dynamic_theme/dynamic_theme.dart';
import 'package:example/custom_host_config/custom_host_config.dart';
import 'package:example/render_time/render_time_page.dart';
import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'about_page.dart';
import 'brightness_switch.dart';
import 'generic_page.dart';
import 'network_page.dart';

void main() {
  debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
  runApp(MyApp());
}

///
/// Uses named routes which are now frowned upon.
/// This is a static app so not a big deal
///
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DynamicTheme(
      defaultBrightness: Brightness.dark,
      data: (brightness) => new ThemeData(
        primarySwatch: Colors.blue,
        brightness: brightness,
      ),
      themedWidgetBuilder: (context, theme) {
        return new MaterialApp(
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('vi', '')],
          title: 'Flutter Adaptive Cards',
          theme: theme,
          home: new MyHomePage(),
          // can use named routes in hard coded demo
          // Inject the resources into to the page
          routes: {
            'Samples': (context) => GenericListPage(
                  // column set only works if markdownEnabled:false
                  title: "Samples (first is markdownEnabled:false)",
                  urls: [
                    "lib/samples/example1",
                    "lib/samples/example1",
                    "lib/samples/example2",
                    "lib/samples/example3",
                    "lib/samples/example4",
                    "lib/samples/example5",
                    "lib/samples/example6",
                    "lib/samples/example7",
                    "lib/samples/example8",
                    "lib/samples/example9",
                    "lib/samples/example10",
                    "lib/samples/example11",
                    "lib/samples/example12",
                    "lib/samples/example13",
                    "lib/samples/example14",
                    "lib/samples/example15",
                  ],
                  supportMarkdowns: [
                    false,
                    true,
                    true,
                    true,
                    true,
                    true,
                    true,
                    true,
                    true,
                    true,
                    true,
                    true,
                    true,
                    true,
                    true,
                    true,
                  ],
                ),
            'Samples with dynamic HostConfig': (context) =>
                DynamicHostConfigPage(),
            'TextBlock': (context) => GenericListPage(
                  title: "TextBlock (last is markdownEnabled:false)",
                  urls: [
                    "lib/text_block/example1",
                    "lib/text_block/example2",
                    "lib/text_block/example3",
                    "lib/text_block/example4",
                    "lib/text_block/example5",
                    "lib/text_block/example6",
                    "lib/text_block/example7",
                    "lib/text_block/example8",
                    "lib/text_block/example9",
                    "lib/text_block/example10",
                    "lib/text_block/example11",
                  ],
                  supportMarkdowns: [
                    true,
                    true,
                    true,
                    true,
                    true,
                    true,
                    true,
                    true,
                    true,
                    true,
                    false
                  ],
                ),
            'Image': (context) => GenericListPage(title: 'Image', urls: [
                  "lib/image/example1",
                  "lib/image/example2",
                  "lib/image/example3",
                  "lib/image/example4",
                  "lib/image/example5",
                  "lib/image/example6",
                  "lib/image/width_and_heigh_set_in_pixels",
                  "lib/image/width_set_in_pixels",
                  "lib/image/height_set_in_pixels",
                ]),
            'Container': (context) =>
                GenericListPage(title: "Container", urls: [
                  "lib/container/example1",
                  "lib/container/example2",
                  "lib/container/example3",
                  "lib/container/example4",
                  "lib/container/example5",
                ]),
            'ColumnSet': (context) => GenericListPage(
                  title: "ColumnSet",
                  urls: [
                    "lib/column_set/example1",
                    "lib/column_set/example2",
                    "lib/column_set/example3",
                    "lib/column_set/example4",
                    "lib/column_set/example5",
                    "lib/column_set/example6",
                    "lib/column_set/example7",
                    "lib/column_set/example8",
                    "lib/column_set/example9",
                    "lib/column_set/example10",
                    "lib/column_set/column_width_in_pixels",
                  ],
                  supportMarkdowns: [
                    true,
                    true,
                    true,
                    true,
                    false,
                    false,
                    true,
                    true,
                    true,
                    true,
                    false
                  ],
                ),
            'Column': (context) => GenericListPage(title: "Column", urls: [
                  "lib/column/example1",
                  "lib/column/example2",
                  "lib/column/example3",
                  "lib/column/example4",
                  "lib/column/example5"
                ]),
            'FactSet': (context) => GenericListPage(title: 'FactSet', urls: [
                  "lib/fact_set/example1",
                ]),
            'ImageSet': (context) => GenericListPage(title: 'ImageSet', urls: [
                  "lib/image_set/example1",
                  "lib/image_set/example2",
                ]),
            'ActionSet': (context) =>
                GenericListPage(title: 'ActionSet', urls: [
                  "lib/action_set/example1",
                ]),
            'Action.OpenUrl': (context) =>
                GenericListPage(title: 'ActionOpenUrl', urls: [
                  "lib/action_open_url/example1",
                  "lib/action_open_url/example2",
                ]),
            'Action.Submit': (context) =>
                GenericListPage(title: 'ActionSubmit', urls: [
                  "lib/action_submit/example1",
                ]),
            'Action.ShowCard': (context) => GenericListPage(
                title: 'Action.ShowCard',
                urls: ["lib/action_show_card/example1"]),
            'Input.Text': (context) =>
                GenericListPage(title: 'Input.text', urls: [
                  "lib/inputs/input_text/example1",
                  "lib/inputs/input_text/example2",
                ]),
            'Input.Number': (context) => GenericListPage(
                title: 'Input.Number',
                urls: ["lib/inputs/input_number/example1"]),
            'Media': (context) =>
                GenericListPage(title: 'Media', urls: ["lib/media/example1"]),
            'Input.Date': (context) => GenericListPage(
                title: 'Input.Date', urls: ["lib/inputs/input_date/example1"]),
            'Input.Time': (context) =>
                GenericListPage(title: 'Input.Time', urls: [
                  "lib/inputs/input_time/example1",
                  "lib/inputs/input_time/example2",
                ]),
            'Input.Toggle': (context) => GenericListPage(
                title: 'Input.Toggle',
                urls: ["lib/inputs/input_toggle/example1"]),
            'Input.ChoiceSet': (context) => GenericListPage(
                  title: 'Input.ChoiceSet',
                  urls: ["lib/inputs/input_choice_set/example1"],
                ),
            'Table': (context) =>
                GenericListPage(title: 'table', urls: ["lib/table/example1"]),
            'about': (context) => AboutPage(),
            'Render Time': (context) => RenderTimePage(),
            'Network via Assets': (context) => NetworkPage(
                title: "ac-qv-faqs via assets", url: 'assets/ac-qv-faqs.json'),
            'Sample Expense Report': (context) => NetworkPage(
                title: "Expense Report",
                url:
                    'https://raw.githubusercontent.com/microsoft/AdaptiveCards/main/samples/v1.5/Scenarios/ExpenseReport.json'),
            'Sample Show Card Wizard': (context) => NetworkPage(
                title: 'Show Card Wizard',
                url:
                    'https://raw.githubusercontent.com/microsoft/AdaptiveCards/main/samples/v1.5/Scenarios/ShowCardWizard.json'),
            'Sample Agenda': (context) => NetworkPage(
                title: 'Agenda',
                url:
                    'https://raw.githubusercontent.com/microsoft/AdaptiveCards/main/samples/v1.5/Scenarios/Agenda.json'),
          },
        );
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text('Flutter Adaptive Cards'),
        actions: [
          BrightnessSwitch(),
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
      body: ListView(
        padding: EdgeInsets.all(16.0),
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: <Widget>[
                  Image.asset(
                    'assets/banner.jpg',
                  ),
                  Divider(),
                  Text(
                    'Flutter-Adaptive Cards',
                    style:
                        TextStyle(fontSize: 24.0, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          getRow(['Samples', 'Samples with dynamic HostConfig']),
          getRow(['Image', 'ImageSet']),
          getButton('Media'),
          Divider(),
          getRow(['Action.OpenUrl', 'Action.Submit', 'Action.ShowCard']),
          getButton('ActionSet'),
          Divider(),
          getButton('Container'),
          getButton('FactSet'),
          getButton('TextBlock'),
          getRow(['Column', 'ColumnSet']),
          Divider(),
          getRow(['Input.Text', 'Input.Number', 'Input.Date']),
          getRow(['Input.Time', 'Input.Toggle', 'Input.ChoiceSet']),
          Divider(),
          getRow(['Render Time', 'Network via Assets']),
          Text(
            'https://github.com/microsoft/AdaptiveCards/tree/main/samples/v1.5',
            style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          getRow([
            'Sample Expense Report',
            'Sample Show Card Wizard',
            'Sample Agenda'
          ]),
          Divider(),
          getRow(['Table'])
        ],
      ),
    );
  }

  ///
  /// list of buttons whose titles match the named route
  ///
  Widget getRow(List<String> element) {
    return Row(
      children: element
          .map(
            (it) => Expanded(child: getButton(it)),
          )
          .toList(),
    );
  }

  ///
  /// A buton whose title and route action have the same value
  /// i.e. The button title matches the named route
  ///
  Widget getButton(String element) {
    return Card(
      child: InkWell(
          onTap: () => pushNamed(element),
          child: SizedBox(
            height: 64.0,
            child: Center(child: Text(element)),
          )),
    );
  }

  ///
  /// Button action that does a pushName with the passed in text
  ///
  void pushNamed(String element) {
    Navigator.pushNamed(context, element);
  }
}
