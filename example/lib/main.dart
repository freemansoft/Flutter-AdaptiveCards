import 'package:example/render_time/render_time_page.dart';
import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';

import 'about_page.dart';
import 'generic_page.dart';
import 'network_page.dart';
import 'theme_support.dart';

void main() {
  // Should pick up from some override maybe command line?
  debugDefaultTargetPlatformOverride = null;
  // this forces iOS on all platforms
  // debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
  runApp(MyApp());
}

///
/// Uses named routes which are now frowned upon.
/// This is a static app so not a big deal
///
class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  ThemeMode themeMode = ThemeMode.system;
  late FlexScheme usedScheme = FlexScheme.deepBlue;
  // we know this prebuilt scheme exists exists in this map...
  late FlexSchemeData usedSchemeData =
      FlexColor.schemes[usedScheme] as FlexSchemeData;

  @override
  Widget build(BuildContext context) {
    AboutPage aboutPage = AboutPage(
      themeMode: themeMode,
      onThemeModeChanged: (ThemeMode mode) {
        setState(() {
          themeMode = mode;
        });
      },
      flexSchemeData: usedSchemeData,
    );
    return MaterialApp(
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', "US"), Locale('vi', '')],
      title: 'Flutter Adaptive Cards',
      // Generated by https://rydmike.com/flexcolorscheme/themesplayground-v7-1/#/
      // Theme config for FlexColorScheme version 7.1.x. Make sure you use
      // same or higher package version, but still same major version. If you
      // use a lower package version, some properties may not be supported.
      // In that case remove them after copying this theme to your app.
      theme: lightThemeFrom(usedScheme),
      darkTheme: darkThemeFrom(usedScheme),
      // If you do not have a themeMode switch, uncomment this line
      // to let the device system mode control the theme mode:
      // themeMode: ThemeMode.system,
      // Use dark or light theme based on system setting.
      themeMode: themeMode,
      home: new MyHomePage(
        title: 'Flutter Adaptive Cards',
        aboutPage: aboutPage,
      ),
      // can use named routes in hard coded demo
      // Inject the resources into to the page
      routes: {
        'Samples': (context) => GenericListPage(
              // column set only works if markdownEnabled:false
              title: "Samples (first is markdownEnabled:false)",
              urls: [
                "lib/samples/examples/example1",
                "lib/samples/examples/example1",
                "lib/samples/examples/example2",
                "lib/samples/examples/example3",
                "lib/samples/examples/example4",
                "lib/samples/examples/example5",
                "lib/samples/examples/example6",
                "lib/samples/examples/example7",
                "lib/samples/examples/example8",
                "lib/samples/examples/example9",
                "lib/samples/examples/example10",
                "lib/samples/examples/example11",
                "lib/samples/examples/example12",
                "lib/samples/examples/example13",
                "lib/samples/examples/example14",
                "lib/samples/examples/example15",
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
              aboutPage: aboutPage,
            ),
        'TextBlock': (context) => GenericListPage(
              title: "TextBlock (last is markdownEnabled:false)",
              urls: [
                "lib/samples/text_block/example1",
                "lib/samples/text_block/example2",
                "lib/samples/text_block/example3",
                "lib/samples/text_block/example4",
                "lib/samples/text_block/example5",
                "lib/samples/text_block/example6",
                "lib/samples/text_block/example7",
                "lib/samples/text_block/example8",
                "lib/samples/text_block/example9",
                "lib/samples/text_block/example10",
                "lib/samples/text_block/example11",
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
              aboutPage: aboutPage,
            ),
        'Image': (context) => GenericListPage(
              title: 'Image',
              urls: [
                "lib/samples/image/example1",
                "lib/samples/image/example2",
                "lib/samples/image/example3",
                "lib/samples/image/example4",
                "lib/samples/image/example5",
                "lib/samples/image/example6",
                "lib/samples/image/width_and_heigh_set_in_pixels",
                "lib/samples/image/width_set_in_pixels",
                "lib/samples/image/height_set_in_pixels",
              ],
              aboutPage: aboutPage,
            ),
        'Container': (context) => GenericListPage(
              title: "Container",
              urls: [
                "lib/samples/container/example1",
                "lib/samples/container/example2",
                "lib/samples/container/example3",
                "lib/samples/container/example4",
                "lib/samples/container/example5",
              ],
              aboutPage: aboutPage,
            ),
        'ColumnSet': (context) => GenericListPage(
              title: "ColumnSet",
              urls: [
                "lib/samples/column_set/example1",
                "lib/samples/column_set/example2",
                "lib/samples/column_set/example3",
                "lib/samples/column_set/example4",
                "lib/samples/column_set/example5",
                "lib/samples/column_set/example6",
                "lib/samples/column_set/example7",
                "lib/samples/column_set/example8",
                "lib/samples/column_set/example9",
                "lib/samples/column_set/example10",
                "lib/samples/column_set/column_width_in_pixels",
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
              aboutPage: aboutPage,
            ),
        'Column': (context) => GenericListPage(
              title: "Column",
              urls: [
                "lib/samples/column/example1",
                "lib/samples/column/example2",
                "lib/samples/column/example3",
                "lib/samples/column/example4",
                "lib/samples/column/example5"
              ],
              aboutPage: aboutPage,
            ),
        'FactSet': (context) => GenericListPage(
              title: 'FactSet',
              urls: [
                "lib/samples/fact_set/example1",
              ],
              aboutPage: aboutPage,
            ),
        'ImageSet': (context) => GenericListPage(
              title: 'ImageSet',
              urls: [
                "lib/samples/image_set/example1",
                "lib/samples/image_set/example2",
              ],
              aboutPage: aboutPage,
            ),
        'ActionSet': (context) => GenericListPage(
              title: 'ActionSet',
              urls: [
                "lib/samples/action_set/example1",
              ],
              aboutPage: aboutPage,
            ),
        'Action.OpenUrl': (context) => GenericListPage(
              title: 'ActionOpenUrl',
              urls: [
                "lib/samples/action_open_url/example1",
                "lib/samples/action_open_url/example2",
              ],
              aboutPage: aboutPage,
            ),
        'Action.Submit': (context) => GenericListPage(
              title: 'ActionSubmit',
              urls: [
                "lib/samples/action_submit/example1",
              ],
              aboutPage: aboutPage,
            ),
        'Action.ShowCard': (context) => GenericListPage(
              title: 'Action.ShowCard',
              urls: ["lib/samples/action_show_card/example1"],
              aboutPage: aboutPage,
            ),
        'Input.Text': (context) => GenericListPage(
              title: 'Input.text',
              urls: [
                "lib/samples/inputs/input_text/example1",
                "lib/samples/inputs/input_text/example2",
              ],
              aboutPage: aboutPage,
            ),
        'Input.Number': (context) => GenericListPage(
              title: 'Input.Number',
              urls: ["lib/samples/inputs/input_number/example1"],
              aboutPage: aboutPage,
            ),
        'Media': (context) => GenericListPage(
              title: 'Media',
              urls: ["lib/samples/media/example1"],
              aboutPage: aboutPage,
            ),
        'Input.Date': (context) => GenericListPage(
              title: 'Input.Date',
              urls: ["lib/samples/inputs/input_date/example1"],
              aboutPage: aboutPage,
            ),
        'Input.Time': (context) => GenericListPage(
              title: 'Input.Time',
              urls: [
                "lib/samples/inputs/input_time/example1",
                "lib/samples/inputs/input_time/example2",
              ],
              aboutPage: aboutPage,
            ),
        'Input.Toggle': (context) => GenericListPage(
              title: 'Input.Toggle',
              urls: ["lib/samples/inputs/input_toggle/example1"],
              aboutPage: aboutPage,
            ),
        'Input.ChoiceSet': (context) => GenericListPage(
              title: 'Input.ChoiceSet',
              urls: ["lib/samples/inputs/input_choice_set/example1"],
              aboutPage: aboutPage,
            ),
        'Table': (context) => GenericListPage(
              title: 'table',
              urls: ["lib/samples/table/example1"],
              aboutPage: aboutPage,
            ),
        'Render Time': (context) => RenderTimePage(),
        'Network via Assets': (context) => NetworkPage(
              title: "ac-qv-faqs via assets",
              url: 'assets/ac-qv-faqs.json',
              aboutPage: aboutPage,
            ),
        'initData': (context) => GenericListPage(
              title: 'initData loads name, bookingdate and gender',
              urls: [
                "assets/ac-qv-faqs.json",
              ],
              aboutPage: aboutPage,
              // this is a bit of a hack.  initData is sent to every AdaptiveCard in the urls list
              // initData: {
              //   'fullname': 'minato',
              //   'bookingdate': '08/05/2023',
              //   'gender': 'female'
              // },
            ),
        'Sample Expense Report': (context) => NetworkPage(
              title: "Expense Report",
              url:
                  'https://raw.githubusercontent.com/microsoft/AdaptiveCards/main/samples/v1.5/Scenarios/ExpenseReport.json',
              aboutPage: aboutPage,
            ),
        'Sample Show Card Wizard': (context) => NetworkPage(
              title: 'Show Card Wizard',
              url:
                  'https://raw.githubusercontent.com/microsoft/AdaptiveCards/main/samples/v1.5/Scenarios/ShowCardWizard.json',
              aboutPage: aboutPage,
            ),
        'Sample Agenda': (context) => NetworkPage(
              title: 'Agenda',
              url:
                  'https://raw.githubusercontent.com/microsoft/AdaptiveCards/main/samples/v1.5/Scenarios/Agenda.json',
              aboutPage: aboutPage,
            ),
      },
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
          child: ListView(
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
                    style: Theme.of(context).textTheme.displayMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          getRow(context, ['Image', 'ImageSet']),
          getButton(context, 'Media'),
          Divider(),
          getRow(
              context, ['Action.OpenUrl', 'Action.Submit', 'Action.ShowCard']),
          getButton(context, 'ActionSet'),
          Divider(),
          getButton(context, 'Container'),
          getButton(context, 'FactSet'),
          getButton(context, 'TextBlock'),
          getRow(context, ['Column', 'ColumnSet']),
          Divider(),
          getRow(context, ['Input.Text', 'Input.Number', 'Input.Date']),
          getRow(context, ['Input.Time', 'Input.Toggle', 'Input.ChoiceSet']),
          Divider(),
          getRow(context, ['Render Time', 'Network via Assets', 'initData']),
          Divider(),
          Text(
            'https://github.com/microsoft/AdaptiveCards/tree/main/samples/v1.5',
            textAlign: TextAlign.center,
          ),
          getRow(context, [
            'Sample Expense Report',
            'Sample Show Card Wizard',
            'Sample Agenda'
          ]),
          Divider(),
          getRow(context, ['Table'])
        ],
      )),
    );
  }

  ///
  /// list of buttons whose titles match the named route
  ///
  Widget getRow(BuildContext context, List<String> element) {
    return Row(
      children: element
          .map(
            (it) => Expanded(child: getButton(context, it)),
          )
          .toList(),
    );
  }

  ///
  /// A buton whose title and route action have the same value
  /// i.e. The button title matches the named route
  ///
  Widget getButton(BuildContext context, String element) {
    return Card(
      child: InkWell(
          onTap: () => pushNamed(context, element),
          child: SizedBox(
            height: 64.0,
            child: Center(child: Text(element)),
          )),
    );
  }

  ///
  /// Button action that does a pushName with the passed in text
  ///
  void pushNamed(BuildContext context, String element) {
    Navigator.pushNamed(context, element);
  }
}
