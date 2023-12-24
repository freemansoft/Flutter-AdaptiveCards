import 'brightness_switch.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';

class AboutPage extends StatelessWidget {
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final FlexSchemeData flexSchemeData;

  const AboutPage(
      {required this.themeMode,
      required this.onThemeModeChanged,
      required this.flexSchemeData});

  ///
  /// This is so we can style the button the same everywhere.
  /// This assumes the about button is in the app bar
  ///
  Widget aboutButton(BuildContext context) {
    // should be the natural button to support ios
    return MaterialButton(
      onPressed: () {
        showAbout(context);
      },
      child: Text('About',
          style:
              TextStyle(color: Theme.of(context).appBarTheme.foregroundColor)),
    );
  }

  Future<void> showAbout(BuildContext context) {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(content: build(context));
        });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        //padding: EdgeInsets.all(8),
        children: <Widget>[
          BrightnessSwitch(
            themeMode: themeMode,
            onThemeModeChanged: onThemeModeChanged,
            flexSchemeData: flexSchemeData,
          ),
          Divider(),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Neo: AI-Assistant for Enterprise',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  SizedBox(
                    height: 8,
                  ),
                  Text(
                    '''
Neohelden is a startup from Germany developing a digital assistant for enterprise use-cases.

Users can interact with Neo using voice and text and request information from third-party systems or trigger actions – essentially, they're having a conversation with B2B software systems.
Our Conversational Platform allows for easy configuration and extension of Neo's functionalities and integrations, which enables customization of Neo to individual needs and requirements.

Neo has been using Adaptive Cards for a while now, and we're excited to bring them to Flutter!

                  ''',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  SizedBox(
                    height: 8,
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: OutlinedButton(
                      onPressed: () {
                        launchUrl(Uri.parse(
                            'https://neohelden.com/?utm_source=flutter&utm_medium=aboutButton&utm_campaign=flutterDemoApp'));
                      },
                      child: Text('Check out the website'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Image.asset(
                        'assets/norbert.jpg',
                        width: 100,
                      ),
                      SizedBox(
                        width: 16,
                      ),
                      Expanded(
                        child: Column(
                          children: <Widget>[
                            Text(
                              'Norbert Kozsir - former Head of Flutter @Neohelden',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            SizedBox(
                              height: 8,
                            ),
                            Text(
                              'Norbert was the head of Flutter development at Neohelden and '
                              'brought this library to life. '
                              'He is still very active in the Flutter community and keeps rocking every day.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      OutlinedButton(
                        child: Text('Twitter'),
                        onPressed: () {
                          launchUrl(
                              Uri.parse('https://twitter.com/norbertkozsir'));
                        },
                      ),
                      OutlinedButton(
                        child: Text('Medium'),
                        onPressed: () {
                          launchUrl(
                              Uri.parse('https://medium.com/@norbertkozsir'));
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Image.asset(
                        'assets/pascal.jpg',
                        width: 100,
                      ),
                      SizedBox(
                        width: 16,
                      ),
                      Expanded(
                        child: Column(
                          children: <Widget>[
                            Text(
                              'Pascal Stech - Flutter Developer @Neohelden',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            SizedBox(
                              height: 8,
                            ),
                            Text(
                              'Pascal is part of the NeoSEALs team at Neohelden. He currently maintains the Flutter AdaptiveCards implementation.'
                              ' He is also building the Neo Client App using Flutter.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      OutlinedButton(
                        child: Text('GitHub'),
                        onPressed: () {
                          launchUrl(Uri.parse('https://github.com/Curvel'));
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
