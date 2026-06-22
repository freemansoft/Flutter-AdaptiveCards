import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/badge_styles_config.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/chart_colors_config.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/container_style_config.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/container_styles_config.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/font_color_config.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/foreground_colors_config.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/progress_config.dart';
import 'package:flutter_adaptive_cards_fs/src/hostconfig/separator_config.dart';

/// HostConfig color defaults derived from `ThemeData.colorScheme`.
///
/// Used when HostConfig JSON omits color sections. The resolver receives
/// a fresh instance from the ambient theme on each build.
class ThemeColorFallbacks {
  /// Builds color fallbacks from [theme]'s [ColorScheme].
  ThemeColorFallbacks(ThemeData theme) : _theme = theme;

  /// Light-theme fallbacks for HostConfig JSON parsing when no [ThemeData] is
  /// available at parse time.
  static final ThemeColorFallbacks forParsing = ThemeColorFallbacks(
    ThemeData(),
  );

  final ThemeData _theme;

  ColorScheme get _cs => _theme.colorScheme;

  static const double _subtleAlpha = 0.7;

  Color _subtle(Color color) => color.withValues(alpha: _subtleAlpha);

  /// AC-style default/subtle foreground pair for a base [color].
  FontColorConfig fontColorPair(Color color) => FontColorConfig(
    defaultColor: color,
    subtleColor: _subtle(color),
  );

  Color get _warningColor => Color.lerp(_cs.tertiary, _cs.error, 0.45)!;

  /// Default `foregroundColors` section when HostConfig omits it.
  ForegroundColorsConfig get foregroundColors => ForegroundColorsConfig(
    defaultColor: fontColorPair(_cs.onSurface),
    accent: fontColorPair(_cs.primary),
    dark: fontColorPair(_cs.onSurface),
    light: fontColorPair(_cs.onInverseSurface),
    good: fontColorPair(_cs.tertiary),
    warning: fontColorPair(_warningColor),
    attention: fontColorPair(_cs.error),
  );

  /// Default `containerStyles` section when HostConfig omits it.
  ContainerStylesConfig get containerStyles {
    final fg = foregroundColors;
    return ContainerStylesConfig(
      defaultStyle: ContainerStyleConfig(
        backgroundColor: _cs.surface,
        foregroundColors: fg,
      ),
      emphasis: ContainerStyleConfig(
        backgroundColor: _cs.surfaceContainerHighest,
        foregroundColors: fg,
      ),
      good: ContainerStyleConfig(
        backgroundColor: _cs.tertiaryContainer,
        foregroundColors: fg,
      ),
      attention: ContainerStyleConfig(
        backgroundColor: _cs.errorContainer,
        foregroundColors: fg,
      ),
      warning: ContainerStyleConfig(
        backgroundColor: Color.alphaBlend(
          _warningColor.withValues(alpha: 0.25),
          _cs.surface,
        ),
        foregroundColors: fg,
      ),
      accent: ContainerStyleConfig(
        backgroundColor: _cs.primaryContainer,
        foregroundColors: fg,
      ),
    );
  }

  /// Default `progressColors` section when HostConfig omits it.
  ProgressColorsConfig get progressColors => ProgressColorsConfig(
    good: _cs.tertiary,
    warning: _warningColor,
    attention: _cs.error,
    accent: _cs.primary,
    defaultColor: _cs.outline,
  );

  /// Progress track background when HostConfig omits one.
  Color get progressBackgroundColor => _cs.surfaceContainerHighest;

  /// Default `chartColors` section when HostConfig omits it.
  ChartColorsConfig get chartColors => ChartColorsConfig(
    defaultPalette: [
      _cs.primary,
      _cs.secondary,
      _cs.tertiary,
      _cs.error,
      _cs.primaryContainer,
      _cs.secondaryContainer,
      _cs.tertiaryContainer,
      _cs.outline,
    ],
    defaultColor: _cs.primary,
  );

  /// Default `separator` section when HostConfig omits it.
  SeparatorConfig get separator => SeparatorConfig(
    lineColor: _colorToHex(_cs.outline),
    lineThickness: 1,
  );

  /// Default `badgeStyles` section when HostConfig omits it.
  BadgeStylesConfig get badgeStyles {
    final fg = foregroundColors;
    final mutedBg = _cs.surfaceContainerHigh;
    return BadgeStylesConfig(
      filled: BadgeStyleConfig(
        backgroundColors: _badgeBackgroundColors(mutedBg),
        foregroundColors: fg,
      ),
      tint: BadgeStyleConfig(
        backgroundColors: _badgeBackgroundColors(_cs.surfaceContainerHighest),
        foregroundColors: ForegroundColorsConfig(
          defaultColor: fontColorPair(_cs.onSurfaceVariant),
          accent: fontColorPair(_cs.primary),
          dark: fontColorPair(_cs.onSurface),
          light: fontColorPair(_cs.onInverseSurface),
          good: fontColorPair(_cs.tertiary),
          warning: fontColorPair(_warningColor),
          attention: fontColorPair(_cs.error),
        ),
      ),
    );
  }

  ForegroundColorsConfig _badgeBackgroundColors(Color base) {
    return ForegroundColorsConfig(
      defaultColor: fontColorPair(base),
      accent: fontColorPair(_cs.primaryContainer),
      dark: fontColorPair(_cs.surfaceContainerHighest),
      light: fontColorPair(_cs.surfaceContainerLow),
      good: fontColorPair(_cs.tertiaryContainer),
      warning: fontColorPair(
        Color.alphaBlend(
          _warningColor.withValues(alpha: 0.3),
          _cs.surface,
        ),
      ),
      attention: fontColorPair(_cs.errorContainer),
    );
  }

  String _colorToHex(Color color) {
    final argb = color.toARGB32();
    return '#${argb.toRadixString(16).padLeft(8, '0').substring(2)}';
  }
}
