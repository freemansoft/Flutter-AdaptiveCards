import "dart:developer" as developer;

import 'package:flutter/material.dart';
import 'package:format/format.dart';

/// Resolves values based on the host config.
///
/// All values can also be null, in that case the default is used
class ReferenceResolver {
  ReferenceResolver({
    this.currentStyle,
  });

  final String? currentStyle;

  /// Resolves a color type from the Theme palette if colorType is null or 'default'
  /// Resovles a color to the host config if colorType is not null and not 'default'
  ///
  /// Typically one of the following colors:
  /// - default
  /// - dark
  /// - light
  /// - accent
  /// - good
  /// - warning
  /// - attention
  ///
  /// If the color type is 'default' then it picks the standard color for the current style.
  Color? resolveForegroundColor(
      {required BuildContext context, String? colorType, bool? isSubtle}) {
    final String subtleOrDefault = isSubtle ?? false ? 'subtle' : 'default';
    // default or emphasis, I think
    final String myStyle = currentStyle ?? 'default';

    Color? foregroundColor;
    switch (colorType) {
      // "default" means default for the current style
      case "default":
        {
          // derive our foreground color from the theme if the color is set to default

          switch (myStyle) {
            case "default":
              foregroundColor =
                  Theme.of(context).colorScheme.onPrimaryContainer;
            case "emphasis":
              foregroundColor =
                  Theme.of(context).colorScheme.onSecondaryContainer;
            case "good":
              foregroundColor =
                  Theme.of(context).colorScheme.onTertiaryContainer;
            case "attention":
            case "warning:":
              foregroundColor = Theme.of(context).colorScheme.onErrorContainer;
            default:
              foregroundColor =
                  Theme.of(context).colorScheme.onPrimaryContainer;
          }
        }
      // we can override the default foreground for the current background
      case "emphasis":
        foregroundColor = Theme.of(context).colorScheme.onSecondaryContainer;
      case "good":
        foregroundColor = Theme.of(context).colorScheme.onTertiaryContainer;
      case "attention":
      case "warning:":
        foregroundColor = Theme.of(context).colorScheme.onErrorContainer;
      default:
        foregroundColor = null;
    }
    if (foregroundColor != null && subtleOrDefault == "subtle")
      foregroundColor = Color.fromARGB(foregroundColor.alpha ~/ 2,
          foregroundColor.red, foregroundColor.green, foregroundColor.blue);
    assert(() {
      developer.log(
          format("resolved foreground style:{} color:{} subtle:{} to color:{}",
              myStyle, colorType, subtleOrDefault, foregroundColor),
          name: runtimeType.toString());
      return true;
    }());
    return foregroundColor;
  }

  /// Resolves a background color from the host config
  /// Assumes you always want a color call
  ///
  /// Typically one of the following ContainerStyles styles - v 1.0
  ///
  /// - default
  /// - emphasis
  ///
  /// - good added v1.2
  /// - attention added v1.2
  /// - warning added v1.2
  /// - accent added v1.2
  ///
  /// Maps to surface and primaryContainer or SecondaryContainer
  ///
  /// Use resolveBackgroundColorIfNoBackgroundImageAndNoDefaultStyle() if you want no color if nothing specified

  Color? resolveBackgroundColor({
    required BuildContext context,
    required String? style,
  }) {
    String myStyle = style ?? 'default';

    Color? backgroundColor;

    switch (myStyle) {
      case "default":
      case "accent":
        backgroundColor = Theme.of(context).colorScheme.primaryContainer;
      case "emphasis":
        backgroundColor = Theme.of(context).colorScheme.secondaryContainer;
      case "good":
        backgroundColor = Theme.of(context).colorScheme.tertiaryContainer;
      case "attention":
      case "warning:":
        backgroundColor = Theme.of(context).colorScheme.errorContainer;
      default:
        backgroundColor = Theme.of(context).colorScheme.primaryContainer;
    }

    assert(() {
      developer.log(
          format("resolved background style:{} to color:{}", myStyle,
              backgroundColor),
          name: runtimeType.toString());
      return true;
    }());

    return backgroundColor;
  }

  ///
  /// This returns no color if a background image url is provided or if there is no style
  ///
  /// Style is typically one of the ContainerStyles
  /// - default
  /// - emphasis
  ///
  ///
  Color? resolveBackgroundColorIfNoBackgroundImageAndNoDefaultStyle({
    required BuildContext context,
    required String? style,
    required String? backgroundImageUrl,
  }) {
    if (backgroundImageUrl != null) {
      return null;
    }

    if (style == null) return null;

    return resolveBackgroundColor(context: context, style: style.toLowerCase());
  }

  ReferenceResolver copyWith({String? style}) {
    String myStyle = style ?? 'default';
    return ReferenceResolver(
      currentStyle: myStyle,
    );
  }

  /// TODO: hook up to something
  double? resolveSpacing(String? spacing) {
    String mySpacing = spacing ?? 'default';
    if (mySpacing == 'none') return 0.0;
    int? intSpacing = 2;
    assert(intSpacing != null, 'resolve(\'spacing\',\'$mySpacing\') was null');

    return intSpacing?.toDouble();
  }

  /// TODO: Hook this up to something!
  int resolveImageSizes(String sizeDescription) {
    return 64;
  }

  ///TODO: hook this up somehow
  /// "Horizontal" or "Vertical"
  String resolveOrientation(String s) {
    return "Horizontal";
  }
}
