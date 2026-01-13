import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:format/format.dart';

/// Resolves values based on the host config.
///
/// All values can also be null, in that case the default is used
class ReferenceResolver {
  ReferenceResolver({this.currentStyle});

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
  Color? resolveForegroundColor({
    required BuildContext context,
    String? colorType,
    bool? isSubtle,
  }) {
    final String subtleOrDefault = isSubtle ?? false ? 'subtle' : 'default';
    // default or emphasis, I think
    final String myStyle = currentStyle ?? 'default';

    Color? foregroundColor;
    switch (colorType) {
      // "default" means default for the current style
      case 'default':
        {
          // derive our foreground color from the theme if the color is set to default

          switch (myStyle) {
            case 'default':
              foregroundColor =
                  Theme.of(context).colorScheme.onPrimaryContainer;
            case 'emphasis':
              foregroundColor =
                  Theme.of(context).colorScheme.onSecondaryContainer;
            case 'good':
              foregroundColor =
                  Theme.of(context).colorScheme.onTertiaryContainer;
            case 'attention':
            case 'warning:':
              foregroundColor = Theme.of(context).colorScheme.onErrorContainer;
            default:
              foregroundColor =
                  Theme.of(context).colorScheme.onPrimaryContainer;
          }
        }
      // we can override the default foreground for the current background
      case 'emphasis':
        foregroundColor = Theme.of(context).colorScheme.onSecondaryContainer;
      case 'good':
        foregroundColor = Theme.of(context).colorScheme.onTertiaryContainer;
      case 'attention':
      case 'warning:':
        foregroundColor = Theme.of(context).colorScheme.onErrorContainer;
      default:
        foregroundColor = null;
    }
    if (foregroundColor != null && subtleOrDefault == 'subtle') {
      foregroundColor = Color.fromARGB(
        foregroundColor.a ~/ 2,
        foregroundColor.r.toInt(),
        foregroundColor.g.toInt(),
        foregroundColor.b.toInt(),
      );
    }
    assert(() {
      developer.log(
        format(
          'resolved foreground style:{} color:{} subtle:{} to color:{}',
          myStyle,
          colorType,
          subtleOrDefault,
          foregroundColor,
        ),
        name: runtimeType.toString(),
      );
      return true;
    }());
    return foregroundColor;
  }

  Color? resolveButtonBackgroundColor({
    required BuildContext context,
    required String? style,
  }) {
    String myStyle = style ?? 'default';

    Color? backgroundColor;

    switch (myStyle) {
      case 'default':
      case 'positive':
        backgroundColor = Theme.of(context).colorScheme.primaryContainer;
      case 'destructive':
        backgroundColor = Theme.of(context).colorScheme.errorContainer;
      default:
        backgroundColor = Theme.of(context).colorScheme.primaryContainer;
    }

    assert(() {
      developer.log(
        format(
          'resolved background style:{} to color:{}',
          myStyle,
          backgroundColor,
        ),
        name: runtimeType.toString(),
      );
      return true;
    }());

    return backgroundColor;
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
      case 'default':
      case 'accent':
        backgroundColor = Theme.of(context).colorScheme.primaryContainer;
      case 'emphasis':
        backgroundColor = Theme.of(context).colorScheme.secondaryContainer;
      case 'good':
        backgroundColor = Theme.of(context).colorScheme.tertiaryContainer;
      case 'attention':
      case 'warning:':
        backgroundColor = Theme.of(context).colorScheme.errorContainer;
      default:
        backgroundColor = Theme.of(context).colorScheme.primaryContainer;
    }

    assert(() {
      developer.log(
        format(
          'resolved background style:{} to color:{}',
          myStyle,
          backgroundColor,
        ),
        name: runtimeType.toString(),
      );
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
    return ReferenceResolver(currentStyle: myStyle);
  }

  /// TODO: hook up to something
  double? resolveSpacing(String? spacing) {
    String mySpacing = spacing ?? 'default';
    if (mySpacing == 'none') return 0.0;
    int? intSpacing = 2;

    return intSpacing.toDouble();
  }

  /// TODO: Hook this up to something!
  int resolveImageSizes(String sizeDescription) {
    return 64;
  }

  ///TODO: hook this up somehow
  /// "Horizontal" or "Vertical"
  String resolveOrientation(String s) {
    return 'Horizontal';
  }

  /// Resolves font weight from a string value
  ///
  /// Typically one of:
  /// - default
  /// - lighter
  /// - bolder
  FontWeight resolveWeight(String? weightString) {
    String weight = weightString?.toLowerCase() ?? 'default';
    switch (weight) {
      case 'default':
        return FontWeight.normal;
      case 'lighter':
        return FontWeight.w300;
      case 'bolder':
        return FontWeight.bold;
      default:
        return FontWeight.normal;
    }
  }

  /// Resolves font size from a string value using the theme
  ///
  /// Typically one of:
  /// - default
  /// - small
  /// - medium
  /// - large
  /// - extraLarge
  double resolveSize({required BuildContext context, String? sizeString}) {
    String size = sizeString?.toLowerCase() ?? 'default';
    TextTheme textTheme = Theme.of(context).textTheme;
    TextStyle? textStyle;
    switch (size) {
      case 'default':
        textStyle = textTheme.bodyMedium;
      case 'small':
        textStyle = textTheme.bodySmall;
      case 'medium':
        textStyle = textTheme.bodyMedium;
      case 'large':
        textStyle = textTheme.bodyLarge;
      case 'extralarge':
        textStyle = textTheme.titleLarge;
      default: // in case some invalid value
        // should log here for debugging
        textStyle = textTheme.bodyMedium;
    }
    // Style might not exist but that seems unlikely
    double? fontSize = textStyle?.fontSize;
    assert(() {
      if (fontSize == null) {
        developer.log(
          format('Unable to find TextStyle for {}', size),
          name: runtimeType.toString(),
        );
      }
      return true;
    }());
    return fontSize ?? 12.0;
  }

  /// Resolves horizontal alignment from a string value
  ///
  /// Typically one of:
  /// - left
  /// - center
  /// - right
  Alignment resolveAlignment(String? alignmentString) {
    String alignment = alignmentString?.toLowerCase() ?? 'left';
    switch (alignment) {
      case 'left':
        return Alignment.centerLeft;
      case 'center':
        return Alignment.center;
      case 'right':
        return Alignment.centerRight;
      default:
        return Alignment.centerLeft;
    }
  }

  /// Resolves text alignment from a string value
  ///
  /// Typically one of:
  /// - left
  /// - center
  /// - right
  TextAlign resolveTextAlign(String? alignmentString) {
    String alignment = alignmentString?.toLowerCase() ?? 'left';
    switch (alignment) {
      case 'left':
        return TextAlign.start;
      case 'center':
        return TextAlign.center;
      case 'right':
        return TextAlign.right;
      default:
        return TextAlign.start;
    }
  }

  /// Resolves max lines based on wrap and maxLines values
  ///
  /// This also takes care of the wrap property, because maxLines = 1 => no wrap
  int resolveMaxLines({bool? wrap, int? maxLines}) {
    bool shouldWrap = wrap ?? false;
    if (!shouldWrap) return 1;
    // can be null, but that's okay for the text widget.
    // int cannot be null
    return maxLines ?? 1;
  }
}
