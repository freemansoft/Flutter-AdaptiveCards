import 'dart:ui';

import 'package:flutter/material.dart';

class HostConfig {
  HostConfig(
      {this.supportsInteractivity = true,
      this.fontFamily,
      this.spacing,
      this.separator,
      this.fontWeight,
      this.imageSizes,
      this.containerStyles});

  String choiceSetInputValueSeparator = ",";
  bool supportsInteractivity = true;
  String fontFamily = "Segoe UI";
  Spacing spacing = Spacing();
  Separator separator = Separator();
  FontSizes fontSizes = FontSizes();
  FontWeight fontWeight = FontWeight();
  ImageSizes imageSizes = ImageSizes();
  ContainerStyles containerStyles = ContainerStyles();
  Actions actions = Actions();
  ImageSet imageSet = ImageSet();
  FactSet factSet = FactSet();
}

class Spacing {
  Spacing({this.none, this.small, this.standard, this.medium, this.large, this.extraLarge, this.padding});

  int none = 0;
  int small = 3;
  int standard = 8;
  int medium = 20;
  int large = 30;
  int extraLarge = 40;
  int padding = 10;
}

class Separator {
  Separator({this.lineThickness, this.lineColor});

  int lineThickness = 1;
  Color lineColor = Color(0xFFEEEEEE);
}

class FontSizes {
  FontSizes({this.small, this.standard, this.medium, this.large, this.extraLarge});

  int small = 12;
  int standard = 14;
  int medium = 17;
  int large = 21;
  int extraLarge = 26;
}

class FontWeight {
  FontWeight({this.lighter, this.standard, this.bolder});

  int lighter = 200;
  int standard = 400;
  int bolder = 600;
}

class ImageSizes {
  ImageSizes({this.small, this.medium, this.large});

  int small = 40;
  int medium = 80;
  int large = 160;
}

class ContainerStyles {
  ContainerStyles({this.standard, this.emphasis});

  ContainerStyle standard = ContainerStyle(
    foregroundColors: ForegroundColors(),
    backgroundColor: Color(0xFFFFFFFF),
  );
  ContainerStyle emphasis = ContainerStyle(
    foregroundColors: ForegroundColors(),
    backgroundColor: Color(0x08000000),
  );
}

class ContainerStyle {
  ContainerStyle({this.foregroundColors, this.backgroundColor});

  ForegroundColors foregroundColors;
  Color backgroundColor;
}

class ForegroundColors {
  ForegroundColors({this.standard, this.dark, this.light, this.accent, this.good, this.warning, this.attention});

  ForegroundColor standard = ForegroundColor(standard: Color(0xFF333333), subtle: Color(0xEE333333));
  ForegroundColor dark = ForegroundColor(standard: Color(0xFF000000), subtle: Color(0x66000000));
  ForegroundColor light = ForegroundColor(standard: Color(0xFFFFFFFF), subtle: Color(0x33000000));
  ForegroundColor accent = ForegroundColor(standard: Color(0xFF2E89FC), subtle: Color(0x882E89FC));
  ForegroundColor good = ForegroundColor(standard: Color(0xFF54a254), subtle: Color(0xDD54a254));
  ForegroundColor warning = ForegroundColor(standard: Color(0xFFc3ab23), subtle: Color(0xDDc3ab23));
  ForegroundColor attention = ForegroundColor(standard: Color(0xFFFF0000), subtle: Color(0xDDFF0000));
}

class ForegroundColor {
  ForegroundColor({this.standard, this.subtle});

  Color standard;
  Color subtle;
}

class Actions {
  int maxActions = 5;
  String spacing = "default";
  int buttonSpacing = 10;
  bool preExpandSingleShowCardAction = false;
  String actionsOrientation = "Horizontal";
  String actionAlignment = "Left";
}

class ShowCard {
  String actionMode;
  String inlineTopMargin;
  String style;
}

class ImageSet {
  ImageSet({this.imageSize, this.maxImageHeight});

  String imageSize;
  int maxImageHeight;
}

class FactSet {
  FactSet({this.title, this.value, this.spacing});

  FactStyle title = FactStyle(size: "Default", color: "Default", isSubtle: false, weight: "Bolder", wrap: true);

  FactStyle value = FactStyle(size: "Default", color: "Default", isSubtle: false, weight: "Default", wrap: true);

  int spacing = 10;
}

class FactStyle {
  FactStyle({this.size, this.color, this.isSubtle, this.weight, this.wrap});

  String size;
  String color;
  bool isSubtle;
  String weight;
  bool wrap;
}
