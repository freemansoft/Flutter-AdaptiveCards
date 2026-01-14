import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:format/format.dart';

/// Resolves values based on the host config.
///
/// All values can also be null, in that case the default is used
class ReferenceResolver {
  ReferenceResolver({this.currentContainerStyle});

  // used for locally overriding the default style like in nested containers
  final String? currentContainerStyle;

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
  Color? resolveContainerForegroundColor({
    required BuildContext context,
    String? style,
    bool? isSubtle,
  }) {
    final String subtleOrDefault = isSubtle ?? false ? 'subtle' : 'default';
    // inherited container style used if this widget is using default
    // style if passed in and not default
    // then currentcontainer style if set
    // else finally default
    final String myStyle = (style != null && style != 'default')
        ? style
        : (currentContainerStyle != null && currentContainerStyle != 'default')
        ? currentContainerStyle as String
        : 'default';

    Color? foregroundColor;

    // this should be themed and support light and dark
    // TODO note that contained continers behave differently
    // https://adaptivecards.io/explorer/Container.html
    switch (myStyle) {
      case 'default': // black in demo
        foregroundColor =
            Theme.of(context).textTheme.bodySmall?.color ?? Colors.black;
      case 'dark':
        foregroundColor =
            Theme.of(context).textTheme.bodySmall?.color ?? Colors.black;
      case 'light':
        foregroundColor = Colors.grey;
      case 'accent': // blue in demo
        foregroundColor = Colors.blueAccent;
      case 'good': // green in demo
        foregroundColor = Colors.greenAccent;
      case 'attention': // red in demo
        foregroundColor = Theme.of(context).colorScheme.onErrorContainer;
      case 'warning': // orange in demo
        foregroundColor = Theme.of(context).colorScheme.onErrorContainer;
      default:
      // this was null in some cases to inherit the current text color
      // foregroundColor = Theme.of(context).colorScheme.onPrimaryContainer;
    }

    if (foregroundColor != null && subtleOrDefault == 'subtle') {
      foregroundColor = foregroundColor.withValues(
        alpha: foregroundColor.a * .9,
      );
    }
    assert(() {
      developer.log(
        format(
          'resolved foreground style:{} color:{} subtle:{} to color:{}',
          myStyle,
          style,
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
  /// Use resolveContainerBackgroundColorIfNoBackgroundAndNoStyle() if you want no color if nothing specified

  Color? resolveContainerBackgroundColor({
    required BuildContext context,
    required String? style,
  }) {
    // style if passed in and not default
    // then currentcontainer style if set
    // else finally default
    final String myStyle = (style != null && style != 'default')
        ? style
        : (currentContainerStyle != null)
        ? currentContainerStyle as String
        : 'default';

    Color? backgroundColor;

    switch (myStyle) {
      case 'default':
      case 'emphasis':
        backgroundColor = Theme.of(context).colorScheme.primaryContainer;
      case 'accent': // blue in demo
        backgroundColor = Colors.blueAccent;
      case 'good': // green in demo
        backgroundColor = Colors.greenAccent;
      case 'attention': // red in demo
        backgroundColor = Theme.of(context).colorScheme.errorContainer;
      case 'warning': // orange in demo
        backgroundColor = Theme.of(context).colorScheme.errorContainer;
      default:
      //backgroundColor = Theme.of(context).colorScheme.primaryContainer;
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
  /// This returns no color
  /// if a background image url is provided
  /// or if there is no style in the json
  ///
  /// Style is typically one of the ContainerStyles
  /// - default
  /// - emphasis
  ///
  ///
  Color? resolveContainerBackgroundColorIfNoBackgroundAndNoStyle({
    required BuildContext context,
    required String? style,
    required String? backgroundImageUrl,
  }) {
    if (backgroundImageUrl != null) {
      return null;
    }

    if (style == null) return null;

    return resolveContainerBackgroundColor(
      context: context,
      style: style.toLowerCase(),
    );
  }

  ReferenceResolver copyWith({String? style}) {
    String myStyle = style ?? 'default';
    return ReferenceResolver(currentContainerStyle: myStyle);
  }

  /// TODO: hook up to something
  double? resolveSpacing(String? spacing) {
    String mySpacing = spacing ?? 'default';
    if (mySpacing == 'none') return 0.0;
    int? intSpacing = 2;

    return intSpacing.toDouble();
  }

  /// Should standardize this or look up current zoom
  int resolveImageSizes(String sizeDescription) {
    switch (sizeDescription) {
      case 'small':
        return 64;
      case 'medium':
        return 64;
      case 'large':
        return 64;
      default:
        return 64;
    }
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
  FontWeight resolveFontWeight(String? weightString) {
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
  double resolveFontSize({required BuildContext context, String? sizeString}) {
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

  // Returns a font family name or null if no FontType is specified
  String? resolveFontType(BuildContext context, String? typeString) {
    String? type = typeString?.toLowerCase();
    String? currentFontFamily = DefaultTextStyle.of(context).style.fontFamily;
    switch (type) {
      case 'default':
        return currentFontFamily;
      case 'monospace':
        // this is a guess and should come from somewhere
        return currentFontFamily;
      default:
        return currentFontFamily;
    }
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
      default: // should this be null to inherit
        return Alignment.centerLeft;
    }
  }

  Alignment? resolveContainerAlignment(String? horizontalAlignment) {
    horizontalAlignment = horizontalAlignment?.toLowerCase() ?? '';

    switch (horizontalAlignment) {
      case 'left':
        return Alignment.topLeft;
      case 'center':
        return Alignment.topCenter;
      case 'right':
        return Alignment.topRight;
      default:
        return null;
    }
  }

  CrossAxisAlignment resolveHorzontalCrossAxisAlignment(
    String? horizontalAlignment,
  ) {
    horizontalAlignment = horizontalAlignment?.toLowerCase() ?? 'left';
    switch (horizontalAlignment) {
      case 'left':
        return CrossAxisAlignment.start;
      case 'center':
        return CrossAxisAlignment.center;
      case 'right':
        return CrossAxisAlignment.end;
      default:
        return CrossAxisAlignment.start;
    }
  }

  MainAxisAlignment resolveVerticalMainAxisAlginment(
    String? verticalAlignment,
  ) {
    verticalAlignment = verticalAlignment?.toLowerCase() ?? 'top';

    switch (verticalAlignment) {
      case 'top':
        return MainAxisAlignment.start;
      case 'center':
        return MainAxisAlignment.center;
      case 'bottom':
        return MainAxisAlignment.end;
      default:
        return MainAxisAlignment.start;
    }
  }

  MainAxisAlignment resolveHorizontalMainAxisAlginment(
    String? horizontalAlignment,
  ) {
    horizontalAlignment = horizontalAlignment?.toLowerCase() ?? 'top';

    switch (horizontalAlignment) {
      case 'left':
        return MainAxisAlignment.start;
      case 'center':
        return MainAxisAlignment.center;
      case 'right':
        return MainAxisAlignment.end;
      default:
        return MainAxisAlignment.start;
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
