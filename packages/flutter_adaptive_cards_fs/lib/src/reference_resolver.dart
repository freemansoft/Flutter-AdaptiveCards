import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/actions_config.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/adaptive_card_config.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/badge_styles_config.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/chart_colors_config.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/charts_layout_config.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/container_style_config.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/container_styles_config.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/fact_set_config.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/fallback_configs.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/font_color_config.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/font_sizes_config.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/font_weights_config.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/host_config.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/host_widths_config.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/image_set_config.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/image_sizes_config.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/inputs_config.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/media_config.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/progress_config.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/separator_config.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/spacings_config.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/text_block_config.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/text_style_config.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/text_styles_config.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/theme_color_fallbacks.dart';
import 'package:flutter_adaptive_cards_fs/src/models/resolved_text_appearance.dart';
import 'package:flutter_adaptive_cards_fs/src/responsive/width_bucket.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';

/// HostConfig and container-style resolution facade.
///
/// Element and action factories are provided separately via Riverpod
/// `cardTypeRegistryProvider` and `actionTypeRegistryProvider`.
///
/// All JSON values can also be null, in that case the default is used or null.
///
/// https://github.com/microsoft/AdaptiveCards/blob/main/schemas/1.5.0/adaptive-card.json
///
class ReferenceResolver {
  /// Creates a resolver bound to [hostConfigs] and optional inherited style
  /// context.
  ReferenceResolver({
    this.inheritedContainerStyle,
    this.inheritedHorizontalAlignment,
    required this.hostConfigs,
    required this.colorFallbacks,
  });

  ReferenceResolver._({
    this.inheritedContainerStyle,
    this.inheritedHorizontalAlignment,
    required this.hostConfigs,
    required this.colorFallbacks,
  });

  /// Foreground palette context pushed to descendants by ChildStyler.
  final String? inheritedContainerStyle;

  /// Horizontal alignment pushed to descendants when not set on an element.
  final String? inheritedHorizontalAlignment;

  /// Host styling configuration (light/dark selection via [HostConfigs.current]).
  final HostConfigs hostConfigs;

  /// Theme-derived color defaults when HostConfig omits color sections.
  final ThemeColorFallbacks colorFallbacks;

  /// Computes the container-style context children inherit after this
  /// container.
  static String? inheritedContainerStyleForChildren({
    required String? parentInherited,
    required String? ownContainerStyle,
  }) {
    final own = ownContainerStyle?.toLowerCase();
    if (own != null && own != 'default') {
      return own;
    }
    if (own == 'default') {
      return 'default';
    }
    return parentInherited;
  }

  /// Computes horizontal alignment children inherit after this container.
  static String? inheritedHorizontalAlignmentForChildren({
    required String? parentInherited,
    required String? ownAlignment,
  }) {
    final own = ownAlignment?.toLowerCase();
    if (own != null && own.isNotEmpty) {
      return own;
    }
    return parentInherited;
  }

  /// Returns the active [HostConfigs] bundle.
  HostConfigs getHostConfigs() => hostConfigs;

  /// Image set sizing and layout defaults from HostConfig.
  ImageSetConfig? getImageSetConfig() => hostConfigs.current.imageSet;

  /// Action strip defaults (orientation, spacing) from HostConfig.
  ActionsConfig? getActionsConfig() => hostConfigs.current.actions;

  /// Root card padding and spacing defaults from HostConfig.
  AdaptiveCardConfig? getAdaptiveCardConfig() =>
      hostConfigs.current.adaptiveCard;

  /// Container style palette (default, emphasis, semantic colors).
  ContainerStylesConfig? getContainerStylesConfig() =>
      hostConfigs.current.containerStyles;

  /// Fact set title/value spacing and typography from HostConfig.
  FactSetConfig? getFactSetConfig() => hostConfigs.current.factSet;

  /// Named font size scale from HostConfig.
  FontSizesConfig? getFontSizesConfig() => hostConfigs.current.fontSizes;

  /// Named font weight scale from HostConfig.
  FontWeightsConfig? getFontWeightsConfig() => hostConfigs.current.fontWeights;

  /// Named image size scale from HostConfig.
  ImageSizesConfig? getImageSizesConfig() => hostConfigs.current.imageSizes;

  /// Input label and error styling from HostConfig.
  InputsConfig? getInputsConfig() => hostConfigs.current.inputs;

  /// Media playback defaults from HostConfig.
  MediaConfig? getMediaConfig() => hostConfigs.current.media;

  /// Separator line color and thickness from HostConfig.
  SeparatorConfig? getSeparatorConfig() => hostConfigs.current.separator;

  /// Named spacing scale from HostConfig.
  SpacingsConfig? getSpacingsConfig() => hostConfigs.current.spacing;

  /// Text block wrapping and spacing defaults from HostConfig.
  TextBlockConfig? getTextBlockConfig() => hostConfigs.current.textBlock;

  /// Named text styles (heading, column header) from HostConfig.
  TextStylesConfig? getTextStylesConfig() => hostConfigs.current.textStyles;

  /// Badge foreground/background palettes from HostConfig.
  BadgeStylesConfig? getBadgeStylesConfig() => hostConfigs.current.badgeStyles;

  /// Progress bar and ring size defaults from HostConfig.
  ProgressSizesConfig? getProgressSizesConfig() =>
      hostConfigs.current.progressSizes;

  /// Progress foreground/background colors from HostConfig.
  ProgressColorsConfig? getProgressColorConfig() =>
      hostConfigs.current.progressColors;

  /// Chart color palette from HostConfig.
  ChartColorsConfig? getChartColorsConfig() => hostConfigs.current.chartColors;

  /// Chart layout dimensions and chrome from HostConfig.
  ChartsLayoutConfig? getChartsLayoutConfig() =>
      hostConfigs.current.chartsLayout;

  /// JSON Schema definition "Colors"
  ///
  /// Resolves a color type from the Theme palette if colorType is null or
  /// 'default' Resovles a color to the host config if colorType is not null and
  /// not 'default'
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
  /// If the color type is 'default' then it picks the standard color for the
  /// current style.
  Color? resolveContainerForegroundColor({
    String? style,
    bool? isSubtle,
  }) {
    final String subtleOrDefault = isSubtle ?? false ? 'subtle' : 'default';
    // inherited container style used if this widget is using default
    // style if passed in and not default
    // then currentcontainer style if set
    // else finally default
    final String colorToken = switch (style) {
      null || 'default' => 'default',
      final value => value,
    };

    Color? foregroundColor;
    final ContainerStyleConfig containerStyle =
        _containerStyleConfigForInherited(inheritedContainerStyle);

    final FontColorConfig colorConfig = containerStyle.foregroundColors
        .fontColorConfig(colorToken);
    foregroundColor = (isSubtle ?? false)
        ? colorConfig.subtleColor
        : colorConfig.defaultColor;

    assert(() {
      developer.log(
        'resolved foreground inherited:$inheritedContainerStyle '
        'colorToken:$colorToken color:$style '
        'subtle:$subtleOrDefault to color:$foregroundColor',
        name: runtimeType.toString(),
      );
      return true;
    }());
    return foregroundColor;
  }

  /// JSON Schema definition "ContainerStyle" Resolves a background color from
  /// the host config Assumes you always want a color call
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
  /// Use resolveContainerBackgroundColorIfNoBackgroundAndNoStyle() if you want
  /// no color if nothing specified

  Color? resolveContainerBackgroundColor({
    required String? style,
    String? defaultStyle = 'default',
  }) {
    // Background uses only this element's own style — never inherited context.
    final String? myStyle = (style != null && style != 'default')
        ? style.toLowerCase()
        : defaultStyle;

    Color? backgroundColor;

    switch (myStyle) {
      case 'emphasis':
        backgroundColor =
            getContainerStylesConfig()?.emphasis.backgroundColor ??
            colorFallbacks.containerStyles.emphasis.backgroundColor;
      case 'good':
        backgroundColor =
            getContainerStylesConfig()?.good?.backgroundColor ??
            colorFallbacks.containerStyles.good?.backgroundColor;
      case 'attention':
        backgroundColor =
            getContainerStylesConfig()?.attention?.backgroundColor ??
            colorFallbacks.containerStyles.attention?.backgroundColor;
      case 'warning':
        backgroundColor =
            getContainerStylesConfig()?.warning?.backgroundColor ??
            colorFallbacks.containerStyles.warning?.backgroundColor;
      case 'accent':
        backgroundColor =
            getContainerStylesConfig()?.accent?.backgroundColor ??
            colorFallbacks.containerStyles.accent?.backgroundColor;
      case 'default':
        backgroundColor =
            getContainerStylesConfig()?.defaultStyle.backgroundColor ??
            colorFallbacks.containerStyles.defaultStyle.backgroundColor;
      default:
        backgroundColor = null;
    }

    assert(() {
      developer.log(
        'resolved background style:$myStyle to color:$backgroundColor',
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
        'resolved background style:$myStyle to color:$backgroundColor',
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
        'resolved foreground style:$myStyle to color:$foregroundColor',
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

  /// Resolve the foreground color for inputs
  Color? resolveInputForegroundColor({
    required BuildContext context,
    String? style,
  }) {
    //return Theme.of(context).textTheme.bodyMedium?.color;
    final ContainerStyleConfig? containerStyle =
        getContainerStylesConfig()?.defaultStyle;
    final FontColorConfig colorConfig =
        containerStyle?.foregroundColors.fontColorConfig(style) ??
        colorFallbacks.containerStyles.defaultStyle.foregroundColors
            .fontColorConfig(style);
    return colorConfig.defaultColor;
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

  /// Returns a resolver with updated inherited style or alignment context.
  ReferenceResolver copyWith({
    String? inheritedContainerStyle,
    String? inheritedHorizontalAlignment,
  }) {
    return ReferenceResolver._(
      inheritedContainerStyle:
          inheritedContainerStyle ?? this.inheritedContainerStyle,
      inheritedHorizontalAlignment:
          inheritedHorizontalAlignment ?? this.inheritedHorizontalAlignment,
      hostConfigs: hostConfigs,
      colorFallbacks: colorFallbacks,
    );
  }

  ContainerStyleConfig _containerStyleConfigForInherited(String? inherited) {
    final styles = getContainerStylesConfig() ?? colorFallbacks.containerStyles;
    switch (inherited?.toLowerCase()) {
      case 'emphasis':
        return styles.emphasis;
      case 'good':
        return styles.good ?? styles.defaultStyle;
      case 'attention':
        return styles.attention ?? styles.defaultStyle;
      case 'warning':
        return styles.warning ?? styles.defaultStyle;
      case 'accent':
        return styles.accent ?? styles.defaultStyle;
      case 'default':
      default:
        return styles.defaultStyle;
    }
  }

  /// Element horizontalAlignment with parent inheritance applied.
  String resolveEffectiveHorizontalAlignment(String? elementValue) {
    return elementValue?.toLowerCase() ??
        inheritedHorizontalAlignment ??
        'left';
  }

  /// Whether an Image uses circular person clipping.
  bool resolveImageIsPerson(String? imageStyle) {
    return imageStyle?.toLowerCase() == 'person';
  }

  /// Merges [TextStylesConfig] defaults for [styleName] with element overrides.
  ResolvedTextAppearance resolveTextBlockStyle({
    required String? styleName,
    String? size,
    String? weight,
    String? color,
    String? fontType,
    bool? isSubtle,
  }) {
    final normalized = _normalizeTextBlockStyleName(styleName);
    if (normalized != 'default' &&
        normalized != 'heading' &&
        normalized != 'columnheader') {
      assert(() {
        developer.log(
          'Unknown TextBlock style "$styleName"; using default',
          name: runtimeType.toString(),
        );
        return true;
      }());
    }

    final TextStyleConfig? defaults = switch (normalized) {
      'heading' => _headingTextStyleConfig(),
      'columnheader' => _columnHeaderTextStyleConfig(),
      _ => null,
    };

    return ResolvedTextAppearance(
      size: size ?? defaults?.size,
      weight: weight ?? defaults?.weight,
      color: color ?? defaults?.color,
      fontType: fontType ?? defaults?.fontType,
      isSubtle: isSubtle ?? defaults?.isSubtle ?? false,
    );
  }

  String _normalizeTextBlockStyleName(String? styleName) {
    final normalized = styleName?.toLowerCase() ?? 'default';
    if (normalized == 'columnheader' || normalized == 'column_header') {
      return 'columnheader';
    }
    return normalized;
  }

  TextStyleConfig _headingTextStyleConfig() {
    return getTextStylesConfig()?.heading ??
        TextStylesConfig.fromJson(const {}).heading;
  }

  TextStyleConfig _columnHeaderTextStyleConfig() {
    return getTextStylesConfig()?.columnHeader ??
        TextStylesConfig.fromJson(const {}).columnHeader;
  }

  /// Resolves action or layout orientation to `Horizontal` or `Vertical`.
  String resolveOrientation(String? orientation) {
    final String myOrientation =
        orientation?.toLowerCase() ??
        getActionsConfig()?.actionsOrientation.toLowerCase() ??
        'horizontal';
    return myOrientation == 'vertical' ? 'Vertical' : 'Horizontal';
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
    final String alignment = resolveEffectiveHorizontalAlignment(
      alignmentString,
    );
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
    if (horizontalAlignment == null && inheritedHorizontalAlignment == null) {
      return null;
    }
    final String myHorizontalAlignment = resolveEffectiveHorizontalAlignment(
      horizontalAlignment,
    );

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
    final String myHorizontalAlignment = resolveEffectiveHorizontalAlignment(
      horizontalAlignment,
    );
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

  /// JSON Schema definition "VerticalAlignment" Used in Table and Table Row
  /// Used in Column Used in Container
  ///
  /// JSON Schema definition "VerticalContentAlignment"
  /// "VerticalCellContentAlignment" Defines how content should be aligned
  /// vertically within the container
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
    final String myHorizontalAlignment = resolveEffectiveHorizontalAlignment(
      horizontalAlignment,
    );

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
    final String alignment = resolveEffectiveHorizontalAlignment(
      alignmentString,
    );
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

  /// Responsive width breakpoints from HostConfig (null → spec defaults).
  HostWidthsConfig? getHostWidthsConfig() =>
      hostConfigs.current.hostWidthBreakpoints;

  /// Resolves the [WidthBucket] for a card render [width] in logical pixels.
  WidthBucket resolveWidthBucket(double width) =>
      HostWidthsConfig.resolveBucket(getHostWidthsConfig(), width);

  /// Resolves a named spacing token to logical pixels.
  double resolveSpacing(String? spacing) {
    return SpacingsConfig.resolveSpacing(getSpacingsConfig(), spacing);
  }

  /// Separator line thickness from HostConfig, with library fallback.
  double resolveSeparatorThickness() {
    return getSeparatorConfig()?.lineThickness.toDouble() ??
        colorFallbacks.separator.lineThickness.toDouble();
  }

  /// Separator line color from HostConfig, with library fallback.
  Color resolveSeparatorColor() {
    return parseHexColor(getSeparatorConfig()?.lineColor) ??
        parseHexColor(colorFallbacks.separator.lineColor) ??
        colorFallbacks.progressBackgroundColor;
  }

  /// Corner radius (logical pixels) for the Microsoft Teams `roundedCorners`
  /// extension, from HostConfig `cornerRadius`.
  ///
  /// `roundedCorners` is a Teams Adaptive Cards property (Container,
  /// ColumnSet, Column, Table, Image — this package wires `Container` only
  /// so far), not part of the base Adaptive Cards schema. See
  /// https://learn.microsoft.com/en-us/microsoftteams/platform/task-modules-and-cards/cards/cards-format.
  /// Falls back to `FallbackConfigs.cornerRadius` (8) when HostConfig
  /// doesn't specify one.
  double resolveCornerRadius() {
    return hostConfigs.current.cornerRadius ?? FallbackConfigs.cornerRadius;
  }

  /// Get border color based on grid style
  Color resolveGridStyleColor(String style) {
    switch (style.toLowerCase()) {
      case 'emphasis':
        return resolveContainerForegroundColor(
              style: 'default',
              isSubtle: true,
            ) ??
            colorFallbacks.foregroundColors.defaultColor.subtleColor;
      case 'good':
        return resolveContainerForegroundColor(style: 'good') ??
            colorFallbacks.foregroundColors.good.defaultColor;
      case 'attention':
        return resolveContainerForegroundColor(style: 'attention') ??
            colorFallbacks.foregroundColors.attention.defaultColor;
      case 'warning':
        return resolveContainerForegroundColor(style: 'warning') ??
            colorFallbacks.foregroundColors.warning.defaultColor;
      case 'accent':
        return resolveContainerForegroundColor(style: 'accent') ??
            colorFallbacks.foregroundColors.accent.defaultColor;
      case 'default':
      default:
        return resolveContainerForegroundColor(
              style: 'default',
              isSubtle: true,
            ) ??
            colorFallbacks.foregroundColors.defaultColor.subtleColor;
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

  /// Resolves the background color for a progress element
  Color resolveProgressBackgroundColor() {
    return colorFallbacks.progressBackgroundColor;
  }

  /// Resolves progress indicator fill color from a color token.
  Color? resolveProgressColor(String? color) {
    return ProgressColorsConfig.resolveProgressColor(
      config: getProgressColorConfig(),
      color: color,
      fallbackDefaults: colorFallbacks.progressColors,
    );
  }

  /// Resolves the foreground color for a Badge
  Color? resolveBadgeForegroundColor({
    String? colorStyle,
    String? appearance,
    bool? isSubtle,
  }) {
    final myBadgeStyles = getBadgeStylesConfig() ?? colorFallbacks.badgeStyles;

    final String myColorStyle = colorStyle ?? 'default';
    final BadgeStyleConfig badgeStyle = (appearance?.toLowerCase() == 'tint')
        ? myBadgeStyles.tint
        : myBadgeStyles.filled;
    final FontColorConfig colorConfig = badgeStyle.foregroundColors
        .fontColorConfig(myColorStyle);
    final Color foregroundColor = (isSubtle ?? false)
        ? colorConfig.subtleColor
        : colorConfig.defaultColor;

    return foregroundColor;
  }

  /// Resolves the background color for a Badge
  Color? resolveBadgeBackgroundColor({
    String? colorStyle,
    String? appearance,
  }) {
    final myBadgeStyles = getBadgeStylesConfig() ?? colorFallbacks.badgeStyles;

    final String myColorStyle = colorStyle ?? 'default';
    final BadgeStyleConfig badgeStyle = (appearance?.toLowerCase() == 'tint')
        ? myBadgeStyles.tint
        : myBadgeStyles.filled;
    final FontColorConfig colorConfig = badgeStyle.backgroundColors
        .fontColorConfig(myColorStyle);
    final Color backgroundColor = colorConfig.defaultColor;

    return backgroundColor;
  }

  /// Resolves the title text style for a compound button
  TextStyle resolveCompoundButtonTitleStyle() {
    return const TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 16,
    );
  }

  /// Resolves the description text style for a compound button
  TextStyle resolveCompoundButtonDescriptionStyle() {
    return TextStyle(
      fontSize: 12,
      color:
          resolveContainerForegroundColor(
            style: 'default',
            isSubtle: true,
          ) ??
          colorFallbacks.foregroundColors.defaultColor.subtleColor,
    );
  }

  /// Resolves layout settings for `Chart.Line`.
  LineChartLayout resolveLineChartLayout() =>
      ChartsLayoutConfig.resolveLineLayout(getChartsLayoutConfig());

  /// Resolves layout settings for bar chart types.
  BarChartLayout resolveBarChartLayout() =>
      ChartsLayoutConfig.resolveBarLayout(getChartsLayoutConfig());

  /// Resolves layout settings for `Chart.Pie`.
  PieChartLayout resolvePieChartLayout() =>
      ChartsLayoutConfig.resolvePieLayout(getChartsLayoutConfig());

  /// Resolves layout settings for `Chart.Donut` and `Chart.Gauge`.
  DonutChartLayout resolveDonutChartLayout() =>
      ChartsLayoutConfig.resolveDonutLayout(getChartsLayoutConfig());

  /// Resolves the color palette for charts, optionally using element
  /// `colorSet`.
  List<Color> resolveChartPalette({String? colorSet}) {
    final setName = parseChartColorSetName(colorSet);
    if (setName != ChartColorSetName.defaultPalette) {
      return chartPaletteForSet(setName);
    }

    final hostPalette = getChartColorsConfig()?.defaultPalette;
    if (hostPalette != null && hostPalette.isNotEmpty) {
      return hostPalette;
    }

    return colorFallbacks.chartColors.defaultPalette.isNotEmpty
        ? colorFallbacks.chartColors.defaultPalette
        : kChartCategoricalPalette;
  }

  /// Resolves a single chart color from a string (hex or semantic / Teams token).
  Color resolveChartColor(String? colorStr, {Color? fallback}) {
    final tokenColor = resolveChartColorToken(colorStr);
    if (tokenColor != null) {
      return tokenColor;
    }

    if (colorStr == null) {
      return fallback ??
          getChartColorsConfig()?.defaultColor ??
          colorFallbacks.chartColors.defaultColor;
    }

    return parseHexColor(colorStr) ??
        fallback ??
        getChartColorsConfig()?.defaultColor ??
        colorFallbacks.chartColors.defaultColor;
  }
}
