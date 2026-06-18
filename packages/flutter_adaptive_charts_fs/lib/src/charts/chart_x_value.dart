/// Converts a chart data point's `x` field to a plottable double.
///
/// Numbers pass through. ISO-8601 date/datetime strings are converted to
/// epoch milliseconds so time-series points plot in correct order and spacing.
/// Anything unparseable yields `0.0`.
double parseChartXValue(dynamic raw) {
  if (raw is num) return raw.toDouble();
  if (raw is String) {
    final parsed = DateTime.tryParse(raw);
    if (parsed != null) return parsed.millisecondsSinceEpoch.toDouble();
  }
  return 0;
}
