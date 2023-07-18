import 'package:flex_color_scheme/flex_color_scheme.dart';

import 'package:flutter/material.dart';

class BrightnessSwitch extends StatelessWidget {
  const BrightnessSwitch(
      {required this.themeMode,
      required this.onThemeModeChanged,
      required this.flexSchemeData});
  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final FlexSchemeData flexSchemeData;

  @override
  Widget build(BuildContext context) {
    // A 3-way theme mode toggle switch that shows the color scheme.
    return FlexThemeModeSwitch(
      // showSystemMode: false,
      themeMode: themeMode,
      onThemeModeChanged: onThemeModeChanged,
      // The `FlexThemeModeSwitch` has a `FlexSchemeData` property that
      // it uses to set colors on the theme mode buttons and to
      // display theme name and description. Since we passed in our
      // custom scheme data, with name and all, from main here to
      // the HomePage , we just pass it on to the FlexThemeModeSwitch.
      flexSchemeData: flexSchemeData,
      buttonOrder: FlexThemeModeButtonOrder.lightSystemDark,
    );
  }
}
