import 'package:dynamic_theme/dynamic_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class BrightnessSwitch extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Switch(
      value: DynamicTheme.of(context).brightness == Brightness.light,
      activeTrackColor: Colors.white,
      activeColor: Colors.grey,
      inactiveTrackColor: Colors.white,
      onChanged: (value) => {DynamicTheme.of(context).setBrightness(value ? Brightness.light : Brightness.dark)},
    );
  }
}
