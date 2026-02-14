import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/src/hostconfig/badge_styles_config.dart';
import 'package:flutter_adaptive_cards/src/hostconfig/container_styles_config.dart';
import 'package:flutter_adaptive_cards/src/hostconfig/font_color_config.dart';
import 'package:flutter_adaptive_cards/src/hostconfig/font_config.dart';
import 'package:flutter_adaptive_cards/src/hostconfig/foreground_colors_config.dart';
import 'package:flutter_adaptive_cards/src/hostconfig/image_sizes_config.dart';
import 'package:flutter_adaptive_cards/src/hostconfig/miscellaneous_configs.dart';
import 'package:flutter_adaptive_cards/src/hostconfig/progress_config.dart';

class FallbackConfigs {
  static final fallbackProgressSizesConfig = ProgressSizesConfig(
    tiny: 10,
    small: 20,
    medium: 30,
    large: 40,
    extraLarge: 50,
    defaultSize: 30,
  );

  static final fallbackProgressColorsConfig = ProgressColorsConfig(
    good: Colors.green,
    warning: Colors.yellow,
    attention: Colors.red,
    accent: Colors.blue,
    defaultColor: Colors.grey,
  );

  // completely hacky fallback that will teach people to use HostConfig
  static final fallbackBadgeStylesConfig = BadgeStylesConfig(
    filled: BadgeStyleConfig(
      backgroundColors: ForegroundColorsConfig(
        defaultColor: FontColorConfig(
          defaultColor: Colors.grey.shade200,
          subtleColor: Colors.grey.shade100,
        ),
        accent: FontColorConfig(
          defaultColor: Colors.grey.shade200,
          subtleColor: Colors.grey.shade100,
        ),
        dark: FontColorConfig(
          defaultColor: Colors.black,
          subtleColor: Colors.black,
        ),
        light: FontColorConfig(
          defaultColor: Colors.white,
          subtleColor: Colors.white,
        ),
        good: FontColorConfig(
          defaultColor: Colors.green.shade200,
          subtleColor: Colors.green.shade100,
        ),
        warning: FontColorConfig(
          defaultColor: Colors.orange.shade200,
          subtleColor: Colors.orange.shade100,
        ),
        attention: FontColorConfig(
          defaultColor: Colors.red.shade200,
          subtleColor: Colors.red.shade100,
        ),
      ),
      foregroundColors: ForegroundColorsConfig(
        defaultColor: FontColorConfig(
          defaultColor: Colors.black,
          subtleColor: Colors.black,
        ),
        accent: FontColorConfig(
          defaultColor: Colors.blue,
          subtleColor: Colors.blue,
        ),
        dark: FontColorConfig(
          defaultColor: Colors.white,
          subtleColor: Colors.white,
        ),
        light: FontColorConfig(
          defaultColor: Colors.black,
          subtleColor: Colors.black,
        ),
        good: FontColorConfig(
          defaultColor: Colors.green,
          subtleColor: Colors.green,
        ),
        warning: FontColorConfig(
          defaultColor: Colors.deepOrange,
          subtleColor: Colors.deepOrange,
        ),
        attention: FontColorConfig(
          defaultColor: Colors.red,
          subtleColor: Colors.red,
        ),
      ),
    ),
    tint: BadgeStyleConfig(
      backgroundColors: ForegroundColorsConfig(
        defaultColor: FontColorConfig(
          defaultColor: Colors.blueGrey.shade200,
          subtleColor: Colors.blueGrey.shade100,
        ),
        accent: FontColorConfig(
          defaultColor: Colors.blueGrey.shade200,
          subtleColor: Colors.blueGrey.shade100,
        ),
        dark: FontColorConfig(
          defaultColor: Colors.blueGrey.shade200,
          subtleColor: Colors.blueGrey.shade100,
        ),
        light: FontColorConfig(
          defaultColor: Colors.blueGrey.shade200,
          subtleColor: Colors.blueGrey.shade100,
        ),
        good: FontColorConfig(
          defaultColor: Colors.blueGrey.shade200,
          subtleColor: Colors.blueGrey.shade100,
        ),
        warning: FontColorConfig(
          defaultColor: Colors.blueGrey.shade200,
          subtleColor: Colors.blueGrey.shade100,
        ),
        attention: FontColorConfig(
          defaultColor: Colors.blueGrey.shade200,
          subtleColor: Colors.blueGrey.shade100,
        ),
      ),
      foregroundColors: ForegroundColorsConfig(
        defaultColor: FontColorConfig(
          defaultColor: Colors.grey,
          subtleColor: Colors.grey,
        ),
        accent: FontColorConfig(
          defaultColor: Colors.blueAccent,
          subtleColor: Colors.blueAccent,
        ),
        dark: FontColorConfig(
          defaultColor: Colors.blueGrey,
          subtleColor: Colors.blueGrey,
        ),
        light: FontColorConfig(
          defaultColor: Colors.blueGrey,
          subtleColor: Colors.blueGrey,
        ),
        good: FontColorConfig(
          defaultColor: Colors.greenAccent,
          subtleColor: Colors.greenAccent,
        ),
        warning: FontColorConfig(
          defaultColor: Colors.orangeAccent,
          subtleColor: Colors.orangeAccent,
        ),
        attention: FontColorConfig(
          defaultColor: Colors.redAccent,
          subtleColor: Colors.redAccent,
        ),
      ),
    ),
  );

  static final SpacingsConfig spacingsConfig = SpacingsConfig(
    small: 4,
    medium: 8,
    large: 16,
    extraLarge: 32,
    defaultSpacing: 4,
    padding: 20,
  );

  static final ContainerStylesConfig containerStylesConfig =
      ContainerStylesConfig(
        defaultStyle: ContainerStyleConfig(
          backgroundColor: Colors.white,
          foregroundColors: _containerForegroundColorConfig,
        ),
        emphasis: ContainerStyleConfig(
          backgroundColor: Colors.grey,
          foregroundColors: _containerForegroundColorConfig,
        ),
        good: ContainerStyleConfig(
          backgroundColor: const Color(0xFFCCFFCC), // Light green
          foregroundColors: _containerForegroundColorConfig,
        ),
        attention: ContainerStyleConfig(
          backgroundColor: const Color(0xFFFFCCCC), // Light red
          foregroundColors: _containerForegroundColorConfig,
        ),
        warning: ContainerStyleConfig(
          backgroundColor: const Color(0xFFFFE6CC), // Light orange
          foregroundColors: _containerForegroundColorConfig,
        ),
        accent: ContainerStyleConfig(
          backgroundColor: const Color(0xFFCCE6FF), // Light blue
          foregroundColors: _containerForegroundColorConfig,
        ),
      );

  static final ForegroundColorsConfig _containerForegroundColorConfig =
      ForegroundColorsConfig(
        defaultColor: FontColorConfig(
          defaultColor: Colors.black,
          subtleColor: Colors.black.withAlpha(128),
        ),
        accent: FontColorConfig(
          defaultColor: Colors.blue,
          subtleColor: Colors.blue.withAlpha(128),
        ),
        light: FontColorConfig(
          defaultColor: Colors.white,
          subtleColor: Colors.white.withAlpha(128),
        ),
        dark: FontColorConfig(
          defaultColor: Colors.black,
          subtleColor: Colors.black.withAlpha(128),
        ),
        good: FontColorConfig(
          defaultColor: Colors.green,
          subtleColor: Colors.green.withAlpha(128),
        ),
        warning: FontColorConfig(
          defaultColor: Colors.orange,
          subtleColor: Colors.orange.withAlpha(128),
        ),
        attention: FontColorConfig(
          defaultColor: Colors.red,
          subtleColor: Colors.red.withAlpha(128),
        ),
      );

  static final imageSizesConfig = ImageSizesConfig(
    small: 32,
    medium: 64,
    large: 120,
  );

  static final FontWeightsConfig fontWeightsConfig = FontWeightsConfig(
    lighter: FontWeight.w200.value,
    defaultWeight: FontWeight.normal.value,
    bolder: FontWeight.bold.value,
  );

  /// This should come from the theme but we don't have access to the theme
  static final FontSizesConfig fontSizesConfig = FontSizesConfig(
    small: 10,
    defaultSize: 12,
    medium: 14,
    large: 18,
    extraLarge: 22,
  );

  static final SeparatorConfig separatorConfig = SeparatorConfig(
    lineColor: Colors.grey.shade300
        .toARGB32()
        .toRadixString(16)
        .padLeft(6, '0'),
    lineThickness: 1,
  );
}
