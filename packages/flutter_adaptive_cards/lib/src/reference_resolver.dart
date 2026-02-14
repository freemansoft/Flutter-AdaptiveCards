import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards/src/hostconfig/actions_config.dart';
import 'package:flutter_adaptive_cards/src/hostconfig/adaptive_card_config.dart';
import 'package:flutter_adaptive_cards/src/hostconfig/badge_styles_config.dart';
import 'package:flutter_adaptive_cards/src/hostconfig/container_styles_config.dart';
import 'package:flutter_adaptive_cards/src/hostconfig/fact_set_config.dart';
import 'package:flutter_adaptive_cards/src/hostconfig/fallback_configs.dart';
import 'package:flutter_adaptive_cards/src/hostconfig/font_color_config.dart';
import 'package:flutter_adaptive_cards/src/hostconfig/font_config.dart';
import 'package:flutter_adaptive_cards/src/hostconfig/host_config.dart';
import 'package:flutter_adaptive_cards/src/hostconfig/image_set_config.dart';
import 'package:flutter_adaptive_cards/src/hostconfig/image_sizes_config.dart';
import 'package:flutter_adaptive_cards/src/hostconfig/inputs_config.dart';
import 'package:flutter_adaptive_cards/src/hostconfig/miscellaneous_configs.dart';
import 'package:flutter_adaptive_cards/src/hostconfig/progress_config.dart';
import 'package:flutter_adaptive_cards/src/hostconfig/text_style_config.dart';
import 'package:flutter_adaptive_cards/src/utils/utils.dart';
import 'package:format/format.dart';

///
/// All JSON values can also be null, in that case the default is used or null
///
/// https://github.com/microsoft/AdaptiveCards/blob/main/schemas/1.5.0/adaptive-card.json
///
/// Styles not implemented even though we have configs
/// ImageStyle
/// Spacing
/// TextBlockStyle
///
class ReferenceResolver {
  ReferenceResolver({
    this.currentContainerStyle,
    required this.hostConfigs,
  });

  ReferenceResolver._({
    this.currentContainerStyle,
    required this.hostConfigs,
  });

  /// Locally used for containers
  final String? currentContainerStyle;
  final HostConfigs hostConfigs;

  HostConfigs getHostConfigs() => hostConfigs;
  ImageSetConfig? getImageSetConfig() => hostConfigs.current.imageSet;
  ActionsConfig? getActionsConfig() => hostConfigs.current.actions;
  AdaptiveCardConfig? getAdaptiveCardConfig() =>
      hostConfigs.current.adaptiveCard;
  ContainerStylesConfig? getContainerStylesConfig() =>
      hostConfigs.current.containerStyles;
  FactSetConfig? getFactSetConfig() => hostConfigs.current.factSet;
  FontSizesConfig? getFontSizesConfig() => hostConfigs.current.fontSizes;
  FontWeightsConfig? getFontWeightsConfig() => hostConfigs.current.fontWeights;
  ImageSizesConfig? getImageSizesConfig() => hostConfigs.current.imageSizes;
  InputsConfig? getInputsConfig() => hostConfigs.current.inputs;
  MediaConfig? getMediaConfig() => hostConfigs.current.media;
  SeparatorConfig? getSeparatorConfig() => hostConfigs.current.separator;
  SpacingsConfig? getSpacingsConfig() => hostConfigs.current.spacing;
  TextBlockConfig? getTextBlockConfig() => hostConfigs.current.textBlock;
  TextStylesConfig? getTextStylesConfig() => hostConfigs.current.textStyles;
  BadgeStylesConfig? getBadgeStylesConfig() => hostConfigs.current.badgeStyles;
  ProgressSizesConfig? getProgressSizesConfig() =>
      hostConfigs.current.progressSizes;
  ProgressColorsConfig? getProgressColorConfig() =>
      hostConfigs.current.progressColors;

  /// JSON Schema definition "Colors"
  ///
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
        ? currentContainerStyle!
        : 'default';

    Color? foregroundColor;
    // Use the container styles to find the correct foreground color registry
    final ContainerStyleConfig? containerStyle =
        (currentContainerStyle?.toLowerCase() == 'emphasis')
        ? getContainerStylesConfig()?.emphasis
        : getContainerStylesConfig()?.defaultStyle;

    final FontColorConfig colorConfig =
        containerStyle?.foregroundColors.fontColorConfig(myStyle) ??
        FallbackConfigs.containerStylesConfig.defaultStyle.foregroundColors
            .fontColorConfig(myStyle);
    foregroundColor = (isSubtle ?? false)
        ? colorConfig.subtleColor
        : colorConfig.defaultColor;

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

  /// JSON Schema definition "ContainerStyle"
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
    required String? style,
    String? defaultStyle = 'default',
  }) {
    // style if passed in and not default
    // then currentcontainer style if set
    // else finally default
    final String? myStyle = (style != null && style != 'default')
        ? style.toLowerCase()
        : (currentContainerStyle != null)
        ? currentContainerStyle!.toLowerCase()
        : defaultStyle;

    Color? backgroundColor;

    switch (myStyle) {
      case 'emphasis':
        backgroundColor =
            getContainerStylesConfig()?.emphasis.backgroundColor ??
            FallbackConfigs.containerStylesConfig.emphasis.backgroundColor;
      case 'good':
        backgroundColor =
            getContainerStylesConfig()?.good?.backgroundColor ??
            FallbackConfigs.containerStylesConfig.good?.backgroundColor;
      case 'attention':
        backgroundColor =
            getContainerStylesConfig()?.attention?.backgroundColor ??
            FallbackConfigs.containerStylesConfig.attention?.backgroundColor;
      case 'warning':
        backgroundColor =
            getContainerStylesConfig()?.warning?.backgroundColor ??
            FallbackConfigs.containerStylesConfig.warning?.backgroundColor;
      case 'accent':
        backgroundColor =
            getContainerStylesConfig()?.accent?.backgroundColor ??
            FallbackConfigs.containerStylesConfig.accent?.backgroundColor;
      case 'default':
        backgroundColor =
            getContainerStylesConfig()?.defaultStyle.backgroundColor ??
            FallbackConfigs.containerStylesConfig.defaultStyle.backgroundColor;
      default:
        backgroundColor = null;
    }

    assert(() {
      developer.log(
        format(
          'resolved background style:{} to color:{}',
          myStyle ?? '',
          backgroundColor,
        ),
        name: runtimeType.toString(),
      );
      return true;
    }());

    return backgroundColor;
  }

  /// There is no host config for action style :-(
  /// JSON Schema definition "ActionStyle"
  Color? resolveButtonBackgroundColor({
    required BuildContext context,
    required String? style,
  }) {
    final String myStyle = style ?? 'default';

    Color? backgroundColor;

    switch (myStyle) {
      case 'default':
        backgroundColor = Theme.of(context).colorScheme.primary;
      case 'positive':
        backgroundColor = Theme.of(context).colorScheme.secondary;
      case 'destructive':
        backgroundColor = Theme.of(context).colorScheme.error;
      default:
        backgroundColor = Theme.of(context).colorScheme.primary;
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

  /// There is no host config for action style :-(
  /// JSON Schema definition "ActionStyle"
  Color? resolveButtonForegroundColor({
    required BuildContext context,
    required String? style,
  }) {
    final String myStyle = style ?? 'default';

    Color? foregroundColor;

    switch (myStyle) {
      case 'default':
        foregroundColor = Theme.of(context).colorScheme.onPrimary;
      case 'positive':
        foregroundColor = Theme.of(context).colorScheme.onSecondary;
      case 'destructive':
        foregroundColor = Theme.of(context).colorScheme.onError;
      default:
        foregroundColor = Theme.of(context).colorScheme.onPrimary;
    }

    assert(() {
      developer.log(
        format(
          'resolved foreground style:{} to color:{}',
          myStyle,
          foregroundColor,
        ),
        name: runtimeType.toString(),
      );
      return true;
    }());

    return foregroundColor;
  }

  /// Calling from text fields and drop downs, etc
  /// Input fields use the same background colors as containers
  Color? resolveInputBackgroundColor({
    required BuildContext context,
    required String? style,
  }) {
    return resolveContainerBackgroundColor(style: style);
  }

  ///
  /// This returns no color
  /// if a background image url is provided
  /// or no style provided. makes it transparent to background of containing
  ///
  /// Style is typically one of the ContainerStyles
  /// - default
  /// - emphasis
  /// - accent
  /// - good
  /// - attention
  /// - warning
  ///
  ///
  Color? resolveContainerBackgroundColorIfNoBackgroundImage({
    required BuildContext context,
    required String? style,
    required String? backgroundImageUrl,
  }) {
    if (backgroundImageUrl != null) {
      return null;
    }

    // containers could be transparent
    if (style == null) return null;

    return resolveContainerBackgroundColor(
      style: style.toLowerCase(),
    );
  }

  ReferenceResolver copyWith({String? style}) {
    final String myStyle = style ?? 'default';
    return ReferenceResolver._(
      currentContainerStyle: myStyle,
      hostConfigs: hostConfigs,
    );
  }

  // TODO(username): hook this up somehow
  // "Horizontal" or "Vertical"
  String resolveOrientation(String s) {
    return 'Horizontal';
  }

  /// JSON Schema definition "FontWeight"
  /// Resolves font weight from a string value
  ///
  /// Typically one of:
  /// - default
  /// - lighter
  /// - bolder
  FontWeight resolveFontWeight(String? weightString) {
    final String weight = weightString?.toLowerCase() ?? 'default';
    final config = getFontWeightsConfig() ?? FallbackConfigs.fontWeightsConfig;
    int weightValue;
    switch (weight) {
      case 'lighter':
        weightValue = config.lighter;
      case 'bolder':
        weightValue = config.bolder;
      case 'default':
      default:
        weightValue = config.defaultWeight;
    }

    // Map integer weight to Flutter FontWeight
    if (weightValue <= 100) return FontWeight.w100;
    if (weightValue <= 200) return FontWeight.w200;
    if (weightValue <= 300) return FontWeight.w300;
    if (weightValue <= 400) return FontWeight.w400;
    if (weightValue <= 500) return FontWeight.w500;
    if (weightValue <= 600) return FontWeight.w600;
    if (weightValue <= 700) return FontWeight.w700;
    if (weightValue <= 800) return FontWeight.w800;
    return FontWeight.w900;
  }

  /// JSON Schema definition "FontSize"
  /// Resolves font size from a string value using the theme
  ///
  /// Typically one of:
  /// - default
  /// - small
  /// - medium
  /// - large
  /// - extraLarge
  double resolveFontSize({required BuildContext context, String? sizeString}) {
    final String size = sizeString?.toLowerCase() ?? 'default';
    final config = getFontSizesConfig() ?? FallbackConfigs.fontSizesConfig;
    int sizeValue;
    switch (size) {
      case 'small':
        sizeValue = config.small;
      case 'medium':
        sizeValue = config.medium;
      case 'large':
        sizeValue = config.large;
      case 'extralarge':
        sizeValue = config.extraLarge;
      case 'default':
      default:
        sizeValue = config.defaultSize;
    }
    return sizeValue.toDouble();
  }

  /// JSON Schema definition "FontType"
  // Returns a font family name or null if no FontType is specified
  String? resolveFontType(BuildContext context, String? typeString) {
    final String? type = typeString?.toLowerCase();
    final String? currentFontFamily = DefaultTextStyle.of(
      context,
    ).style.fontFamily;
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

  /// JSON Schema definition "HorizontalAlignement" to a specific Flutter type
  ///
  /// Schema definition "HorizontalAlignment"
  /// Resolves horizontal alignment from a string value
  ///
  /// Typically one of:
  /// - left
  /// - center
  /// - right
  Alignment resolveAlignment(String? alignmentString) {
    final String alignment = alignmentString?.toLowerCase() ?? 'left';
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

  /// JSON Schema definition "HorizontalAlignment"
  /// Resolves horizontal alignment from a string value
  ///
  /// Typically one of:
  /// - left
  /// - center
  /// - right
  Alignment? resolveContainerAlignment(String? horizontalAlignment) {
    final String myHorizontalAlignment =
        horizontalAlignment?.toLowerCase() ?? '';

    switch (myHorizontalAlignment) {
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

  /// JSON Schema definition "HorizontalAlignement" to a specific Flutter type
  ///
  /// Schema definition "HorizontalAlignment"
  /// Resolves horizontal alignment from a string value
  ///
  /// Typically one of:
  /// - left
  /// - center
  /// - right
  CrossAxisAlignment resolveHorzontalCrossAxisAlignment(
    String? horizontalAlignment,
  ) {
    final String myHorizontalAlignment =
        horizontalAlignment?.toLowerCase() ?? 'left';
    switch (myHorizontalAlignment) {
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

  /// JSON Schema definition "VerticalAlignment"
  ///   Used in Table and Table Row
  ///   Used in BackgroundImage
  ///
  /// JSON Schema definition "VerticalContentAlignment"
  ///   Defines how content should be aligned vertically within the container
  ///
  // TODO(username): add to all containers
  ///
  /// Resolves vertical alignment from a string value
  ///
  /// Typically one of:
  /// - top
  /// - center
  /// - bottom
  MainAxisAlignment resolveVerticalMainAxisContentAlginment(
    String? verticalAlignment,
  ) {
    final String myVerticalAlignment =
        verticalAlignment?.toLowerCase() ?? 'top';

    switch (myVerticalAlignment) {
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

  /// JSON Schema definition "HorizontalAlignement" to a specific Flutter type
  ///
  /// Schema definition "HorizontalAlignment"
  /// Resolves horizontal alignment from a string value
  ///
  /// Typically one of:
  /// - left
  /// - center
  /// - right
  MainAxisAlignment resolveHorizontalMainAxisAlignment(
    String? horizontalAlignment,
  ) {
    final String myHorizontalAlignment =
        horizontalAlignment?.toLowerCase() ?? 'left';

    switch (myHorizontalAlignment) {
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

  /// JSON Schema definition "HorizontalAlignement" to a specific Flutter type
  ///
  /// Schema definition "TextAlign"
  /// Resolves text alignment from a string value
  ///
  /// Typically one of:
  /// - left
  /// - center
  /// - right
  TextAlign resolveTextAlign(String? alignmentString) {
    final String alignment = alignmentString?.toLowerCase() ?? 'left';
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
    final bool shouldWrap = wrap ?? false;
    if (!shouldWrap) return 1;
    // can be null, but that's okay for the text widget.
    // int cannot be null
    return maxLines ?? 1;
  }

  /// JSON Schema definition "TextBlockStyle"
  /// TextBlockStyle not implemented

  /// still here until we create a config for it
  /// Resolves the font size for a Badge
  double resolveBadgeFontSize(String? size) {
    final String mySize = size?.toLowerCase() ?? 'medium';
    switch (mySize) {
      case 'large':
        return 14;
      case 'medium':
      default:
        return 12;
    }
  }

  double resolveSpacing(String? spacing) {
    return SpacingsConfig.resolveSpacing(getSpacingsConfig(), spacing);
  }

  double resolveSeparatorThickness() {
    return getSeparatorConfig()?.lineThickness.toDouble() ??
        FallbackConfigs.separatorConfig.lineThickness.toDouble();
  }

  Color resolveSeparatorColor() {
    return parseHexColor(getSeparatorConfig()?.lineColor) ??
        parseHexColor(FallbackConfigs.separatorConfig.lineColor) ??
        Colors.grey.shade300;
  }

  /// Get border color based on grid style
  Color resolveGridStyleColor(String style) {
    // Simple color mapping - ideally should use HostConfig
    switch (style.toLowerCase()) {
      case 'emphasis':
        return Colors.grey.shade600;
      case 'good':
        return Colors.green.shade600;
      case 'attention':
        return Colors.red.shade600;
      case 'warning':
        return Colors.orange.shade600;
      case 'accent':
        return Colors.blue.shade600;
      case 'default':
      default:
        return Colors.grey.shade400;
    }
  }

  /// Get vertical alignment for table cells
  TableCellVerticalAlignment resolveTableCellVerticalAlignment(
    String? verticalAlignment,
  ) {
    final alignment = verticalAlignment?.toLowerCase() ?? 'center';

    switch (alignment) {
      case 'top':
        return TableCellVerticalAlignment.top;
      case 'bottom':
        return TableCellVerticalAlignment.bottom;
      case 'center':
      default:
        return TableCellVerticalAlignment.middle;
    }
  }
}
