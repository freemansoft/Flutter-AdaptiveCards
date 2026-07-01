import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A colored segment on the gauge arc.
class GaugeSegment {
  /// Creates a gauge segment with [color], proportional [size], and optional
  /// [legend].
  const GaugeSegment({
    required this.color,
    required this.size,
    this.legend,
  });

  /// Segment fill color.
  final Color color;

  /// Relative size used to proportion segment arcs along the gauge.
  final double size;

  /// Optional legend label for this segment.
  final String? legend;
}

/// How the gauge center value is formatted.
enum GaugeValueFormat {
  /// Display as a percentage of the min–max range (for example `75%`).
  percentage,

  /// Display as value over max (for example `75/100`).
  fraction,
}

/// Maps [value] between [min] and [max] to a fraction in `[0, 1]`.
double normalizeGaugeValue(double value, double min, double max) {
  if (max <= min) {
    return 0;
  }
  return ((value - min) / (max - min)).clamp(0.0, 1.0);
}

/// Converts a normalized fraction to an angle in radians on the semicircular
/// gauge.
///
/// The arc runs from left (π radians) through the top to right (0), clockwise.
double gaugeFractionToAngle(double fraction) => math.pi + fraction * math.pi;

/// Formats the gauge value for display in the chart center.
String formatGaugeValue({
  required double value,
  required double min,
  required double max,
  required GaugeValueFormat format,
}) {
  switch (format) {
    case GaugeValueFormat.percentage:
      final percent = (normalizeGaugeValue(value, min, max) * 100).round();
      return '$percent%';
    case GaugeValueFormat.fraction:
      final displayValue = value.round();
      final displayMax = max.round();
      return '$displayValue/$displayMax';
  }
}

/// Paints a semicircular gauge with colored segments and a value needle.
class GaugePainter extends CustomPainter {
  /// Creates a gauge painter with the given scale, segments, and display
  /// options.
  GaugePainter({
    required this.value,
    required this.min,
    required this.max,
    required this.segments,
    required this.showMinMax,
    required this.valueFormat,
    required this.subLabel,
    required this.trackColor,
    required this.needleColor,
    required this.labelStyle,
    required this.valueStyle,
    required this.subLabelStyle,
  });

  /// Current gauge reading.
  final double value;

  /// Minimum scale value.
  final double min;

  /// Maximum scale value.
  final double max;

  /// Colored arc segments; sizes are proportional weights.
  final List<GaugeSegment> segments;

  /// Whether min and max labels are drawn at the arc ends.
  final bool showMinMax;

  /// Center value display format.
  final GaugeValueFormat valueFormat;

  /// Optional text below the formatted value.
  final String? subLabel;

  /// Background track color behind segments.
  final Color trackColor;

  /// Needle indicator color.
  final Color needleColor;

  /// Style for min/max endpoint labels.
  final TextStyle labelStyle;

  /// Style for the center formatted value.
  final TextStyle valueStyle;

  /// Style for [subLabel].
  final TextStyle subLabelStyle;

  static const double _startAngle = math.pi;
  static const double _sweepAngle = math.pi;
  static const double _strokeWidth = 14;
  static const double _needleLengthFactor = 0.78;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.92);
    final radius = math.min(size.width / 2 - 16, size.height * 0.75);

    final trackRect = Rect.fromCircle(center: center, radius: radius);
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.butt;

    canvas.drawArc(trackRect, _startAngle, _sweepAngle, false, trackPaint);

    _paintSegments(canvas, trackRect);

    final fraction = normalizeGaugeValue(value, min, max);
    final needleAngle = gaugeFractionToAngle(fraction);
    _paintNeedle(canvas, center, radius, needleAngle);

    _paintCenterText(canvas, center, radius);
    if (showMinMax) {
      _paintMinMaxLabels(canvas, center, radius);
    }
  }

  void _paintSegments(Canvas canvas, Rect rect) {
    final totalSize = segments.fold<double>(
      0,
      (sum, segment) => sum + segment.size,
    );
    if (totalSize <= 0) {
      return;
    }

    var currentAngle = _startAngle;
    for (final segment in segments) {
      if (segment.size <= 0) {
        continue;
      }
      final segmentSweep = _sweepAngle * (segment.size / totalSize);
      final paint = Paint()
        ..color = segment.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = _strokeWidth
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect, currentAngle, segmentSweep, false, paint);
      currentAngle += segmentSweep;
    }
  }

  void _paintNeedle(
    Canvas canvas,
    Offset center,
    double radius,
    double angle,
  ) {
    final needleLength = radius * _needleLengthFactor;
    final tip = Offset(
      center.dx + needleLength * math.cos(angle),
      center.dy + needleLength * math.sin(angle),
    );

    final needlePaint = Paint()
      ..color = needleColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(center, tip, needlePaint);

    final hubPaint = Paint()
      ..color = needleColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 5, hubPaint);
  }

  void _paintCenterText(Canvas canvas, Offset center, double radius) {
    final formatted = formatGaugeValue(
      value: value,
      min: min,
      max: max,
      format: valueFormat,
    );

    final valuePainter = TextPainter(
      text: TextSpan(text: formatted, style: valueStyle),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: radius * 1.6);

    final valueOffset = Offset(
      center.dx - valuePainter.width / 2,
      center.dy - radius * 0.45 - valuePainter.height,
    );
    valuePainter.paint(canvas, valueOffset);

    final subLabelText = subLabel;
    if (subLabelText != null && subLabelText.isNotEmpty) {
      final subPainter = TextPainter(
        text: TextSpan(text: subLabelText, style: subLabelStyle),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout(maxWidth: radius * 1.6);

      subPainter.paint(
        canvas,
        Offset(
          center.dx - subPainter.width / 2,
          valueOffset.dy + valuePainter.height + 4,
        ),
      );
    }
  }

  void _paintMinMaxLabels(Canvas canvas, Offset center, double radius) {
    final minText = _formatEndpoint(min);
    final maxText = _formatEndpoint(max);

    _paintEndpointLabel(
      canvas,
      center,
      radius,
      gaugeFractionToAngle(0),
      minText,
      alignLeft: true,
    );
    _paintEndpointLabel(
      canvas,
      center,
      radius,
      gaugeFractionToAngle(1),
      maxText,
      alignLeft: false,
    );
  }

  String _formatEndpoint(double endpoint) {
    if (valueFormat == GaugeValueFormat.percentage) {
      final percent = (normalizeGaugeValue(endpoint, min, max) * 100).round();
      return '$percent%';
    }
    return endpoint.round().toString();
  }

  void _paintEndpointLabel(
    Canvas canvas,
    Offset center,
    double radius,
    double angle,
    String text, {
    required bool alignLeft,
  }) {
    final labelRadius = radius + _strokeWidth + 8;
    final anchor = Offset(
      center.dx + labelRadius * math.cos(angle),
      center.dy + labelRadius * math.sin(angle),
    );

    final painter = TextPainter(
      text: TextSpan(text: text, style: labelStyle),
      textDirection: TextDirection.ltr,
    )..layout();

    final offset = Offset(
      anchor.dx - (alignLeft ? painter.width : 0),
      anchor.dy - painter.height / 2,
    );
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant GaugePainter oldDelegate) {
    return value != oldDelegate.value ||
        min != oldDelegate.min ||
        max != oldDelegate.max ||
        showMinMax != oldDelegate.showMinMax ||
        valueFormat != oldDelegate.valueFormat ||
        subLabel != oldDelegate.subLabel ||
        trackColor != oldDelegate.trackColor ||
        needleColor != oldDelegate.needleColor ||
        segments.length != oldDelegate.segments.length;
  }
}
