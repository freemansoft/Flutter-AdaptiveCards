import 'package:flutter/material.dart';

/// One entry in a chart legend row.
class const ChartLegendEntry({
  /// Display label (series name or slice legend).
  required final String label,

  /// Swatch color for this legend entry.
  required final Color color,
}) {
  /// Creates a legend swatch and label pair.
  this;
}

/// Shared title, chart body, and optional legend layout for chart elements.
class const ChartChrome({
  /// The fl_chart (or custom) chart widget.
  required final Widget chart,

  /// Optional chart title from element JSON `title`.
  final String? title,

  /// Legend rows shown when `showLegend` is true.
  final List<ChartLegendEntry> legendEntries = const [],
  super.key,
}) extends StatelessWidget {
  /// Wraps [chart] with an optional [title] and [legendEntries].
  this;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];

    if (title != null && title!.isNotEmpty) {
      children.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            title!,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      );
    }

    children.add(chart);

    if (legendEntries.isNotEmpty) {
      children.add(
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Wrap(
            spacing: 12,
            runSpacing: 4,
            children: legendEntries
                .map(
                  (entry) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        color: entry.color,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        entry.label,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                )
                .toList(),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }
}
