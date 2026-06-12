import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';

/// Resolved layout values for `Chart.Line` rendering.
///
/// Populated from HostConfig `chartsLayout.line` via [LineChartLayoutSection.toLayout]
/// or [ChartsLayoutConfig.resolveLineLayout]. Chart renderers consume these
/// directly; field names match fl_chart layout options.
class LineChartLayout {
  /// Resolved line chart layout for chart renderers.
  const LineChartLayout({
    required this.height,
    required this.emptyMinX,
    required this.emptyMaxX,
    required this.emptyMinY,
    required this.emptyMaxY,
    required this.degenerateRangeBump,
    required this.zeroRangeFallback,
    required this.yAxisPaddingFactor,
    required this.isCurved,
    required this.barWidth,
    required this.isStrokeCapRound,
    required this.showDots,
    required this.showAreaBelow,
    required this.showTitles,
    required this.showRightTitles,
    required this.showTopTitles,
    required this.showGrid,
    required this.showBorder,
    required this.borderColor,
    required this.borderWidth,
  });

  /// Chart area height in logical pixels.
  final double height;

  /// Placeholder minimum X when the series has no data.
  final double emptyMinX;

  /// Placeholder maximum X when the series has no data.
  final double emptyMaxX;

  /// Placeholder minimum Y when the series has no data.
  final double emptyMinY;

  /// Placeholder maximum Y when the series has no data.
  final double emptyMaxY;

  /// Padding added when the computed Y range is zero (flat series).
  final double degenerateRangeBump;

  /// Fallback Y span when the computed range is zero.
  final double zeroRangeFallback;

  /// Multiplier applied to Y range for headroom above/below data.
  final double yAxisPaddingFactor;

  /// Whether line segments render as curves instead of straight segments.
  final bool isCurved;

  /// Line stroke width (fl_chart `barWidth` on line charts).
  final double barWidth;

  /// Whether line caps render with rounded ends.
  final bool isStrokeCapRound;

  /// Whether data points render as visible dots.
  final bool showDots;

  /// Whether the area below the line is filled.
  final bool showAreaBelow;

  /// Master switch for axis title visibility.
  final bool showTitles;

  /// Whether right-side axis titles are shown.
  final bool showRightTitles;

  /// Whether top axis titles are shown.
  final bool showTopTitles;

  /// Whether grid lines are drawn behind the series.
  final bool showGrid;

  /// Whether a border is drawn around the plot area.
  final bool showBorder;

  /// Plot border color when [showBorder] is true.
  final Color borderColor;

  /// Plot border stroke width when [showBorder] is true.
  final double borderWidth;
}

/// Resolved layout values for bar chart types.
///
/// From HostConfig `chartsLayout.bar` via [BarChartLayoutSection.toLayout] or
/// [ChartsLayoutConfig.resolveBarLayout].
class BarChartLayout {
  /// Resolved bar chart layout for vertical, horizontal, grouped, and stacked charts.
  const BarChartLayout({
    required this.height,
    required this.emptyMaxY,
    required this.maxYPaddingFactor,
    required this.barWidth,
    required this.barsSpace,
    required this.barBorderRadius,
    required this.stackedBarBorderRadius,
    required this.alignment,
    required this.categoryAxisReservedSize,
    required this.categoryLabelFontSize,
    required this.showCategoryTitles,
  });

  /// Chart area height in logical pixels.
  final double height;

  /// Placeholder maximum Y when the series has no data.
  final double emptyMaxY;

  /// Multiplier on max Y for value-axis headroom.
  final double maxYPaddingFactor;

  /// Width of each bar rod.
  final double barWidth;

  /// Gap between rods within a bar group.
  final double barsSpace;

  /// Corner radius for simple and grouped bars.
  final double barBorderRadius;

  /// Corner radius for the outer rod of stacked bars.
  final double stackedBarBorderRadius;

  /// How bar groups align within the plot width.
  final BarChartAlignmentToken alignment;

  /// Vertical space reserved for category axis labels.
  final double categoryAxisReservedSize;

  /// Font size for category axis labels.
  final double categoryLabelFontSize;

  /// Whether category axis titles are shown.
  final bool showCategoryTitles;
}

/// Token for bar group alignment (maps to fl_chart `BarChartAlignment`).
enum BarChartAlignmentToken {
  /// Distribute bars with space around them.
  spaceAround,

  /// Distribute bars with space between them.
  spaceBetween,

  /// Distribute bars with even spacing.
  spaceEvenly,

  /// Align bars to the start.
  start,

  /// Align bars to the end.
  end,
}

/// Resolved layout values for `Chart.Pie`.
///
/// From HostConfig `chartsLayout.pie` via [PieChartLayoutSection.toLayout] or
/// [ChartsLayoutConfig.resolvePieLayout].
class PieChartLayout {
  /// Resolved pie or donut chart layout for chart renderers.
  const PieChartLayout({
    required this.height,
    required this.centerSpaceRadius,
    required this.sectionsSpace,
    required this.sectionRadius,
    required this.titleFontSize,
    required this.titleFontWeight,
    required this.titleColor,
  });

  /// Chart area height in logical pixels.
  final double height;

  /// Inner hole radius; `0` renders a full pie (no donut hole).
  final double centerSpaceRadius;

  /// Gap between adjacent pie sections.
  final double sectionsSpace;

  /// Outer radius of each pie section.
  final double sectionRadius;

  /// Font size for on-slice labels.
  final double titleFontSize;

  /// Font weight for on-slice labels.
  final FontWeight titleFontWeight;

  /// Text color for on-slice labels.
  final Color titleColor;
}

/// Resolved layout values for `Chart.Donut` and `Chart.Gauge` (same shape as pie).
typedef DonutChartLayout = PieChartLayout;

/// HostConfig `chartsLayout.line` section.
///
/// Override fields in host JSON or build in code, then call [toLayout] at render
/// time (or use [ChartsLayoutConfig.resolveLineLayout]).
class LineChartLayoutSection {
  /// HostConfig overrides for line chart layout.
  const LineChartLayoutSection({
    required this.height,
    required this.emptyMinX,
    required this.emptyMaxX,
    required this.emptyMinY,
    required this.emptyMaxY,
    required this.degenerateRangeBump,
    required this.zeroRangeFallback,
    required this.yAxisPaddingFactor,
    required this.isCurved,
    required this.barWidth,
    required this.isStrokeCapRound,
    required this.showDots,
    required this.showAreaBelow,
    required this.showTitles,
    required this.showRightTitles,
    required this.showTopTitles,
    required this.showGrid,
    required this.showBorder,
    required this.borderColor,
    required this.borderWidth,
  });

  /// Parses `chartsLayout.line` from HostConfig JSON.
  factory LineChartLayoutSection.fromJson(
    Map<String, dynamic> json, {
    LineChartLayoutSection? defaults,
  }) {
    final base = defaults ?? ChartsLayoutConfig.defaults.line;
    return LineChartLayoutSection(
      height: (json['height'] as num?)?.toDouble() ?? base.height,
      emptyMinX: (json['emptyMinX'] as num?)?.toDouble() ?? base.emptyMinX,
      emptyMaxX: (json['emptyMaxX'] as num?)?.toDouble() ?? base.emptyMaxX,
      emptyMinY: (json['emptyMinY'] as num?)?.toDouble() ?? base.emptyMinY,
      emptyMaxY: (json['emptyMaxY'] as num?)?.toDouble() ?? base.emptyMaxY,
      degenerateRangeBump:
          (json['degenerateRangeBump'] as num?)?.toDouble() ??
          base.degenerateRangeBump,
      zeroRangeFallback:
          (json['zeroRangeFallback'] as num?)?.toDouble() ??
          base.zeroRangeFallback,
      yAxisPaddingFactor:
          (json['yAxisPaddingFactor'] as num?)?.toDouble() ??
          base.yAxisPaddingFactor,
      isCurved: json['isCurved'] as bool? ?? base.isCurved,
      barWidth: (json['barWidth'] as num?)?.toDouble() ?? base.barWidth,
      isStrokeCapRound:
          json['isStrokeCapRound'] as bool? ?? base.isStrokeCapRound,
      showDots: json['showDots'] as bool? ?? base.showDots,
      showAreaBelow: json['showAreaBelow'] as bool? ?? base.showAreaBelow,
      showTitles: json['showTitles'] as bool? ?? base.showTitles,
      showRightTitles: json['showRightTitles'] as bool? ?? base.showRightTitles,
      showTopTitles: json['showTopTitles'] as bool? ?? base.showTopTitles,
      showGrid: json['showGrid'] as bool? ?? base.showGrid,
      showBorder: json['showBorder'] as bool? ?? base.showBorder,
      borderColor:
          parseHexColor(json['borderColor']?.toString()) ?? base.borderColor,
      borderWidth:
          (json['borderWidth'] as num?)?.toDouble() ?? base.borderWidth,
    );
  }

  /// Chart area height in logical pixels.
  final double height;

  /// Placeholder minimum X when the series has no data.
  final double emptyMinX;

  /// Placeholder maximum X when the series has no data.
  final double emptyMaxX;

  /// Placeholder minimum Y when the series has no data.
  final double emptyMinY;

  /// Placeholder maximum Y when the series has no data.
  final double emptyMaxY;

  /// Padding added when the computed Y range is zero (flat series).
  final double degenerateRangeBump;

  /// Fallback Y span when the computed range is zero.
  final double zeroRangeFallback;

  /// Multiplier applied to Y range for headroom above/below data.
  final double yAxisPaddingFactor;

  /// Whether line segments render as curves instead of straight segments.
  final bool isCurved;

  /// Line stroke width (fl_chart `barWidth` on line charts).
  final double barWidth;

  /// Whether line caps render with rounded ends.
  final bool isStrokeCapRound;

  /// Whether data points render as visible dots.
  final bool showDots;

  /// Whether the area below the line is filled.
  final bool showAreaBelow;

  /// Master switch for axis title visibility.
  final bool showTitles;

  /// Whether right-side axis titles are shown.
  final bool showRightTitles;

  /// Whether top axis titles are shown.
  final bool showTopTitles;

  /// Whether grid lines are drawn behind the series.
  final bool showGrid;

  /// Whether a border is drawn around the plot area.
  final bool showBorder;

  /// Plot border color when [showBorder] is true.
  final Color borderColor;

  /// Plot border stroke width when [showBorder] is true.
  final double borderWidth;

  /// Resolved values for chart widgets at render time.
  LineChartLayout toLayout() => LineChartLayout(
    height: height,
    emptyMinX: emptyMinX,
    emptyMaxX: emptyMaxX,
    emptyMinY: emptyMinY,
    emptyMaxY: emptyMaxY,
    degenerateRangeBump: degenerateRangeBump,
    zeroRangeFallback: zeroRangeFallback,
    yAxisPaddingFactor: yAxisPaddingFactor,
    isCurved: isCurved,
    barWidth: barWidth,
    isStrokeCapRound: isStrokeCapRound,
    showDots: showDots,
    showAreaBelow: showAreaBelow,
    showTitles: showTitles,
    showRightTitles: showRightTitles,
    showTopTitles: showTopTitles,
    showGrid: showGrid,
    showBorder: showBorder,
    borderColor: borderColor,
    borderWidth: borderWidth,
  );
}

/// HostConfig `chartsLayout.bar` section.
class BarChartLayoutSection {
  /// HostConfig overrides for bar chart layout.
  const BarChartLayoutSection({
    required this.height,
    required this.emptyMaxY,
    required this.maxYPaddingFactor,
    required this.barWidth,
    required this.barsSpace,
    required this.barBorderRadius,
    required this.stackedBarBorderRadius,
    required this.alignment,
    required this.categoryAxisReservedSize,
    required this.categoryLabelFontSize,
    required this.showCategoryTitles,
  });

  /// Parses `chartsLayout.bar` from HostConfig JSON.
  factory BarChartLayoutSection.fromJson(
    Map<String, dynamic> json, {
    BarChartLayoutSection? defaults,
  }) {
    final base = defaults ?? ChartsLayoutConfig.defaults.bar;
    return BarChartLayoutSection(
      height: (json['height'] as num?)?.toDouble() ?? base.height,
      emptyMaxY: (json['emptyMaxY'] as num?)?.toDouble() ?? base.emptyMaxY,
      maxYPaddingFactor:
          (json['maxYPaddingFactor'] as num?)?.toDouble() ??
          base.maxYPaddingFactor,
      barWidth: (json['barWidth'] as num?)?.toDouble() ?? base.barWidth,
      barsSpace: (json['barsSpace'] as num?)?.toDouble() ?? base.barsSpace,
      barBorderRadius:
          (json['barBorderRadius'] as num?)?.toDouble() ?? base.barBorderRadius,
      stackedBarBorderRadius:
          (json['stackedBarBorderRadius'] as num?)?.toDouble() ??
          base.stackedBarBorderRadius,
      alignment: _parseBarAlignment(
        json['alignment']?.toString(),
        base.alignment,
      ),
      categoryAxisReservedSize:
          (json['categoryAxisReservedSize'] as num?)?.toDouble() ??
          base.categoryAxisReservedSize,
      categoryLabelFontSize:
          (json['categoryLabelFontSize'] as num?)?.toDouble() ??
          base.categoryLabelFontSize,
      showCategoryTitles:
          json['showCategoryTitles'] as bool? ?? base.showCategoryTitles,
    );
  }

  /// Chart area height in logical pixels.
  final double height;

  /// Placeholder maximum Y when the series has no data.
  final double emptyMaxY;

  /// Multiplier on max Y for value-axis headroom.
  final double maxYPaddingFactor;

  /// Width of each bar rod.
  final double barWidth;

  /// Gap between rods within a bar group.
  final double barsSpace;

  /// Corner radius for simple and grouped bars.
  final double barBorderRadius;

  /// Corner radius for the outer rod of stacked bars.
  final double stackedBarBorderRadius;

  /// How bar groups align within the plot width.
  final BarChartAlignmentToken alignment;

  /// Vertical space reserved for category axis labels.
  final double categoryAxisReservedSize;

  /// Font size for category axis labels.
  final double categoryLabelFontSize;

  /// Whether category axis titles are shown.
  final bool showCategoryTitles;

  /// Resolved values for chart widgets at render time.
  BarChartLayout toLayout() => BarChartLayout(
    height: height,
    emptyMaxY: emptyMaxY,
    maxYPaddingFactor: maxYPaddingFactor,
    barWidth: barWidth,
    barsSpace: barsSpace,
    barBorderRadius: barBorderRadius,
    stackedBarBorderRadius: stackedBarBorderRadius,
    alignment: alignment,
    categoryAxisReservedSize: categoryAxisReservedSize,
    categoryLabelFontSize: categoryLabelFontSize,
    showCategoryTitles: showCategoryTitles,
  );
}

/// HostConfig `chartsLayout.pie` / `chartsLayout.donut` section.
class PieChartLayoutSection {
  /// HostConfig overrides for pie, donut, and gauge chart layout.
  const PieChartLayoutSection({
    required this.height,
    required this.centerSpaceRadius,
    required this.sectionsSpace,
    required this.sectionRadius,
    required this.titleFontSize,
    required this.titleFontWeight,
    required this.titleColor,
  });

  /// Parses `chartsLayout.pie` or `chartsLayout.donut` from HostConfig JSON.
  factory PieChartLayoutSection.fromJson(
    Map<String, dynamic> json, {
    PieChartLayoutSection? defaults,
  }) {
    final base = defaults ?? ChartsLayoutConfig.defaults.pie;
    return PieChartLayoutSection(
      height: (json['height'] as num?)?.toDouble() ?? base.height,
      centerSpaceRadius:
          (json['centerSpaceRadius'] as num?)?.toDouble() ??
          base.centerSpaceRadius,
      sectionsSpace:
          (json['sectionsSpace'] as num?)?.toDouble() ?? base.sectionsSpace,
      sectionRadius:
          (json['sectionRadius'] as num?)?.toDouble() ?? base.sectionRadius,
      titleFontSize:
          (json['titleFontSize'] as num?)?.toDouble() ?? base.titleFontSize,
      titleFontWeight: _parseFontWeight(
        json['titleFontWeight']?.toString(),
        base.titleFontWeight,
      ),
      titleColor:
          parseHexColor(json['titleColor']?.toString()) ?? base.titleColor,
    );
  }

  /// Chart area height in logical pixels.
  final double height;

  /// Inner hole radius; `0` renders a full pie (no donut hole).
  final double centerSpaceRadius;

  /// Gap between adjacent pie sections.
  final double sectionsSpace;

  /// Outer radius of each pie section.
  final double sectionRadius;

  /// Font size for on-slice labels.
  final double titleFontSize;

  /// Font weight for on-slice labels.
  final FontWeight titleFontWeight;

  /// Text color for on-slice labels.
  final Color titleColor;

  /// Resolved values for chart widgets at render time.
  PieChartLayout toLayout() => PieChartLayout(
    height: height,
    centerSpaceRadius: centerSpaceRadius,
    sectionsSpace: sectionsSpace,
    sectionRadius: sectionRadius,
    titleFontSize: titleFontSize,
    titleFontWeight: titleFontWeight,
    titleColor: titleColor,
  );
}

/// HostConfig `chartsLayout` section for chart element dimensions and chrome.
///
/// Attach via `HostConfig.chartsLayout`. Each subsection maps to a chart family;
/// use [resolveLineLayout], [resolveBarLayout], [resolvePieLayout], and
/// [resolveDonutLayout] when rendering (falls back to [defaults]).
class ChartsLayoutConfig {
  /// HostConfig overrides for all chart families; omit fields to keep [defaults].
  const ChartsLayoutConfig({
    required this.line,
    required this.bar,
    required this.pie,
    required this.donut,
  });

  /// Parses `chartsLayout` from HostConfig JSON.
  factory ChartsLayoutConfig.fromJson(Map<String, dynamic> json) {
    return ChartsLayoutConfig(
      line: LineChartLayoutSection.fromJson(
        json['line'] as Map<String, dynamic>? ?? {},
      ),
      bar: BarChartLayoutSection.fromJson(
        json['bar'] as Map<String, dynamic>? ?? {},
      ),
      pie: PieChartLayoutSection.fromJson(
        json['pie'] as Map<String, dynamic>? ?? {},
      ),
      donut: PieChartLayoutSection.fromJson(
        json['donut'] as Map<String, dynamic>? ?? {},
        defaults: ChartsLayoutConfig.defaults.donut,
      ),
    );
  }

  /// Line chart HostConfig subsection.
  final LineChartLayoutSection line;

  /// Bar chart HostConfig subsection.
  final BarChartLayoutSection bar;

  /// Pie chart HostConfig subsection.
  final PieChartLayoutSection pie;

  /// Donut and gauge chart HostConfig subsection.
  final PieChartLayoutSection donut;

  /// Built-in defaults matching pre-config chart rendering behavior.
  static const ChartsLayoutConfig defaults = ChartsLayoutConfig(
    line: LineChartLayoutSection(
      height: 250,
      emptyMinX: 0,
      emptyMaxX: 10,
      emptyMinY: 0,
      emptyMaxY: 10,
      degenerateRangeBump: 1,
      zeroRangeFallback: 10,
      yAxisPaddingFactor: 0.1,
      isCurved: true,
      barWidth: 3,
      isStrokeCapRound: true,
      showDots: false,
      showAreaBelow: false,
      showTitles: true,
      showRightTitles: false,
      showTopTitles: false,
      showGrid: true,
      showBorder: true,
      borderColor: Color(0xff37434d),
      borderWidth: 1,
    ),
    bar: BarChartLayoutSection(
      height: 250,
      emptyMaxY: 10,
      maxYPaddingFactor: 1.2,
      barWidth: 16,
      barsSpace: 4,
      barBorderRadius: 2,
      stackedBarBorderRadius: 0,
      alignment: BarChartAlignmentToken.spaceAround,
      categoryAxisReservedSize: 32,
      categoryLabelFontSize: 10,
      showCategoryTitles: true,
    ),
    pie: PieChartLayoutSection(
      height: 200,
      centerSpaceRadius: 0,
      sectionsSpace: 2,
      sectionRadius: 100,
      titleFontSize: 12,
      titleFontWeight: FontWeight.bold,
      titleColor: Colors.white,
    ),
    donut: PieChartLayoutSection(
      height: 200,
      centerSpaceRadius: 40,
      sectionsSpace: 2,
      sectionRadius: 50,
      titleFontSize: 12,
      titleFontWeight: FontWeight.bold,
      titleColor: Colors.white,
    ),
  );

  /// Layout for `Chart.Line`.
  static LineChartLayout resolveLineLayout(ChartsLayoutConfig? config) =>
      (config?.line ?? ChartsLayoutConfig.defaults.line).toLayout();

  /// Layout for bar chart types (vertical, horizontal, grouped, stacked).
  static BarChartLayout resolveBarLayout(ChartsLayoutConfig? config) =>
      (config?.bar ?? ChartsLayoutConfig.defaults.bar).toLayout();

  /// Layout for `Chart.Pie`.
  static PieChartLayout resolvePieLayout(ChartsLayoutConfig? config) =>
      (config?.pie ?? ChartsLayoutConfig.defaults.pie).toLayout();

  /// Layout for `Chart.Donut` and `Chart.Gauge`.
  static DonutChartLayout resolveDonutLayout(ChartsLayoutConfig? config) =>
      (config?.donut ?? ChartsLayoutConfig.defaults.donut).toLayout();
}

FontWeight _parseFontWeight(String? value, FontWeight fallback) {
  switch (value?.toLowerCase()) {
    case 'bold':
    case 'bolder':
      return FontWeight.bold;
    case 'normal':
    case 'default':
    case 'lighter':
      return FontWeight.normal;
    default:
      return fallback;
  }
}

BarChartAlignmentToken _parseBarAlignment(
  String? value,
  BarChartAlignmentToken fallback,
) {
  switch (value?.toLowerCase()) {
    case 'spacebetween':
      return BarChartAlignmentToken.spaceBetween;
    case 'spaceevenly':
      return BarChartAlignmentToken.spaceEvenly;
    case 'start':
      return BarChartAlignmentToken.start;
    case 'end':
      return BarChartAlignmentToken.end;
    default:
      return fallback;
  }
}
