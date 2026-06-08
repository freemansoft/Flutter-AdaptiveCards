import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';

/// Resolved layout values for `Chart.Line` rendering.
class LineChartLayout {
  /// Creates resolved line chart layout values.
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

  /// Chart container height in logical pixels.
  final double height;

  /// Default minimum X when no data is present.
  final double emptyMinX;

  /// Default maximum X when no data is present.
  final double emptyMaxX;

  /// Default minimum Y when no data is present.
  final double emptyMinY;

  /// Default maximum Y when no data is present.
  final double emptyMaxY;

  /// Amount added to axis bounds when computed range is zero.
  final double degenerateRangeBump;

  /// Fallback Y range when computed range is zero.
  final double zeroRangeFallback;

  /// Multiplier applied to Y range for vertical axis padding.
  final double yAxisPaddingFactor;

  /// Whether line series are rendered as curves.
  final bool isCurved;

  /// Line stroke width.
  final double barWidth;

  /// Whether line caps are rounded.
  final bool isStrokeCapRound;

  /// Whether data point dots are shown.
  final bool showDots;

  /// Whether area below the line is filled.
  final bool showAreaBelow;

  /// Master switch for axis titles.
  final bool showTitles;

  /// Whether right axis titles are shown.
  final bool showRightTitles;

  /// Whether top axis titles are shown.
  final bool showTopTitles;

  /// Whether grid lines are shown.
  final bool showGrid;

  /// Whether the chart border is shown.
  final bool showBorder;

  /// Chart border color.
  final Color borderColor;

  /// Chart border stroke width.
  final double borderWidth;
}

/// Resolved layout values for bar chart types.
class BarChartLayout {
  /// Creates resolved bar chart layout values.
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

  /// Chart container height in logical pixels.
  final double height;

  /// Default maximum Y when no data is present.
  final double emptyMaxY;

  /// Multiplier applied to max Y for value-axis headroom.
  final double maxYPaddingFactor;

  /// Bar rod width.
  final double barWidth;

  /// Space between rods in a group.
  final double barsSpace;

  /// Border radius for simple and grouped bars.
  final double barBorderRadius;

  /// Border radius for stacked bar outer rod.
  final double stackedBarBorderRadius;

  /// Bar group alignment token.
  final BarChartAlignmentToken alignment;

  /// Reserved space for category axis labels.
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
class PieChartLayout {
  /// Creates resolved pie chart layout values.
  const PieChartLayout({
    required this.height,
    required this.centerSpaceRadius,
    required this.sectionsSpace,
    required this.sectionRadius,
    required this.titleFontSize,
    required this.titleFontWeight,
    required this.titleColor,
  });

  /// Chart container height in logical pixels.
  final double height;

  /// Inner hole radius (0 for full pie).
  final double centerSpaceRadius;

  /// Gap between pie sections.
  final double sectionsSpace;

  /// Outer radius of pie sections.
  final double sectionRadius;

  /// On-slice label font size.
  final double titleFontSize;

  /// On-slice label font weight.
  final FontWeight titleFontWeight;

  /// On-slice label color.
  final Color titleColor;
}

/// Resolved layout values for `Chart.Donut` and `Chart.Gauge`.
typedef DonutChartLayout = PieChartLayout;

/// HostConfig `chartsLayout.line` section.
class LineChartLayoutSection {
  /// Creates line chart layout settings.
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

  /// Chart container height in logical pixels.
  final double height;

  /// Default minimum X when no data is present.
  final double emptyMinX;

  /// Default maximum X when no data is present.
  final double emptyMaxX;

  /// Default minimum Y when no data is present.
  final double emptyMinY;

  /// Default maximum Y when no data is present.
  final double emptyMaxY;

  /// Amount added to axis bounds when computed range is zero.
  final double degenerateRangeBump;

  /// Fallback Y range when computed range is zero.
  final double zeroRangeFallback;

  /// Multiplier applied to Y range for vertical axis padding.
  final double yAxisPaddingFactor;

  /// Whether line series are rendered as curves.
  final bool isCurved;

  /// Line stroke width.
  final double barWidth;

  /// Whether line caps are rounded.
  final bool isStrokeCapRound;

  /// Whether data point dots are shown.
  final bool showDots;

  /// Whether area below the line is filled.
  final bool showAreaBelow;

  /// Master switch for axis titles.
  final bool showTitles;

  /// Whether right axis titles are shown.
  final bool showRightTitles;

  /// Whether top axis titles are shown.
  final bool showTopTitles;

  /// Whether grid lines are shown.
  final bool showGrid;

  /// Whether the chart border is shown.
  final bool showBorder;

  /// Chart border color.
  final Color borderColor;

  /// Chart border stroke width.
  final double borderWidth;

  /// Converts this section to resolved layout values.
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
  /// Creates bar chart layout settings.
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

  /// Chart container height in logical pixels.
  final double height;

  /// Default maximum Y when no data is present.
  final double emptyMaxY;

  /// Multiplier applied to max Y for value-axis headroom.
  final double maxYPaddingFactor;

  /// Bar rod width.
  final double barWidth;

  /// Space between rods in a group.
  final double barsSpace;

  /// Border radius for simple and grouped bars.
  final double barBorderRadius;

  /// Border radius for stacked bar outer rod.
  final double stackedBarBorderRadius;

  /// Bar group alignment token.
  final BarChartAlignmentToken alignment;

  /// Reserved space for category axis labels.
  final double categoryAxisReservedSize;

  /// Font size for category axis labels.
  final double categoryLabelFontSize;

  /// Whether category axis titles are shown.
  final bool showCategoryTitles;

  /// Converts this section to resolved layout values.
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
  /// Creates pie or donut chart layout settings.
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

  /// Chart container height in logical pixels.
  final double height;

  /// Inner hole radius (0 for full pie).
  final double centerSpaceRadius;

  /// Gap between pie sections.
  final double sectionsSpace;

  /// Outer radius of pie sections.
  final double sectionRadius;

  /// On-slice label font size.
  final double titleFontSize;

  /// On-slice label font weight.
  final FontWeight titleFontWeight;

  /// On-slice label color.
  final Color titleColor;

  /// Converts this section to resolved layout values.
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
class ChartsLayoutConfig {
  /// Creates chart layout settings for all chart families.
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

  /// Line chart layout section.
  final LineChartLayoutSection line;

  /// Bar chart layout section.
  final BarChartLayoutSection bar;

  /// Pie chart layout section.
  final PieChartLayoutSection pie;

  /// Donut chart layout section.
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
