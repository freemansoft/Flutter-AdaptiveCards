// Host-only demo: rebuilds card JSON from knobs to patch Table column widths,
// grid styling, and a highlighted cell's minHeight / style.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';
import 'package:widgetbook/widgetbook.dart';

import 'package:widgetbook_workspace/widgetbook_card_registry.dart';

/// Column-width options offered by the Table knobs page, in the order shown.
///
/// `auto` sizes a column to its content (consistent across rows), `stretch`
/// fills remaining space, a bare number is a relative flex weight, and `Npx` is
/// a fixed pixel width.
const tableWidthOptions = <String>['auto', 'stretch', '1', '2', '60px', '120px'];

/// Container-style options for the highlighted cell (and `gridStyle`).
const tableStyleOptions = <String>[
  'default',
  'emphasis',
  'good',
  'attention',
  'warning',
  'accent',
];

/// Row/column of the cell the `minHeight` and `style` knobs target.
const _highlightRow = 1;
const _highlightCol = 0;

/// Default knob values extracted from the first Table in a sample card.
class TableKnobDefaults {
  /// Creates defaults for the Table property knobs.
  const TableKnobDefaults({
    this.showGridLines = true,
    this.firstRowAsHeader = true,
    this.gridStyle = 'accent',
    this.columnWidths = const ['auto', 'stretch', '60px', '2'],
  });

  /// Whether grid lines are drawn (`showGridLines`).
  final bool showGridLines;

  /// Whether the first row uses header styling (`firstRowAsHeader`).
  final bool firstRowAsHeader;

  /// Grid line color token (`gridStyle`).
  final String gridStyle;

  /// Per-column `width` values, as strings (e.g. `auto`, `stretch`, `60px`, `2`).
  final List<String> columnWidths;
}

/// Keeps knob-driven Table pages mounted when Widgetbook query params change.
final tableKnobsPageKeys = <String, GlobalKey<State<TableKnobsPage>>>{};

/// Returns a stable [GlobalKey] for the Table knobs page at [assetPath].
GlobalKey<State<TableKnobsPage>> tableKnobsPageKeyFor(String assetPath) {
  return tableKnobsPageKeys.putIfAbsent(
    assetPath,
    GlobalKey<State<TableKnobsPage>>.new,
  );
}

/// Widgetbook page that deep-clones a base card and patches its first Table from
/// knobs, demonstrating `auto`/`stretch`/numeric/`px` column widths plus cell
/// `minHeight` and `style`.
class TableKnobsPage extends StatefulWidget {
  /// Creates a Table knobs page for the sample at [assetPath].
  const TableKnobsPage({required this.assetPath, super.key});

  /// Asset path to the Adaptive Card JSON (Widgetbook bundle path).
  final String assetPath;

  @override
  State<TableKnobsPage> createState() => _TableKnobsPageState();
}

class _TableKnobsPageState extends State<TableKnobsPage> {
  final GlobalKey<RawAdaptiveCardState> _cardKey = GlobalKey();

  Map<String, dynamic>? _baseCardMap;
  TableKnobDefaults? _defaults;

  @override
  void initState() {
    super.initState();
    unawaited(_loadCard());
  }

  Future<void> _loadCard() async {
    final json = await rootBundle.loadString(widget.assetPath);
    final map = jsonDecode(json) as Map<String, dynamic>;
    if (!mounted) {
      return;
    }
    setState(() {
      _baseCardMap = map;
      _defaults = _extractDefaults(map);
    });
  }

  TableKnobDefaults _extractDefaults(Map<String, dynamic> root) {
    final table = _findFirstTable(root);
    if (table == null) {
      return const TableKnobDefaults();
    }

    final columns = (table['columns'] as List<dynamic>?) ?? const [];
    final widths = <String>[
      for (final column in columns)
        if (column is Map<String, dynamic>) _widthToString(column['width']),
    ];

    return TableKnobDefaults(
      showGridLines: table['showGridLines'] as bool? ?? true,
      firstRowAsHeader: table['firstRowAsHeader'] as bool? ?? true,
      gridStyle: table['gridStyle']?.toString() ?? 'accent',
      columnWidths: widths.isEmpty ? const ['stretch'] : widths,
    );
  }

  /// Stringifies a raw `width` JSON value for use as a dropdown initial option.
  String _widthToString(Object? width) {
    if (width is num) {
      return width == width.roundToDouble()
          ? width.toInt().toString()
          : width.toString();
    }
    return width?.toString() ?? 'stretch';
  }

  /// Coerces a dropdown width string back to the JSON form the parser expects:
  /// an int for bare numbers, otherwise the string (`auto`/`stretch`/`Npx`).
  Object _widthFromString(String value) {
    final asInt = int.tryParse(value);
    return asInt ?? value;
  }

  Map<String, dynamic>? _findFirstTable(Object? node) {
    if (node is Map<String, dynamic>) {
      if (node['type'] == 'Table') {
        return node;
      }
      for (final value in node.values) {
        final found = _findFirstTable(value);
        if (found != null) {
          return found;
        }
      }
    } else if (node is List) {
      for (final item in node) {
        final found = _findFirstTable(item);
        if (found != null) {
          return found;
        }
      }
    }
    return null;
  }

  Map<String, dynamic> _cloneAndPatch({
    required bool showGridLines,
    required bool firstRowAsHeader,
    required String gridStyle,
    required List<String> columnWidths,
    required double cellMinHeight,
    required String cellStyle,
  }) {
    final patched =
        jsonDecode(jsonEncode(_baseCardMap)) as Map<String, dynamic>;
    final table = _findFirstTable(patched);
    if (table == null) {
      return patched;
    }

    table['showGridLines'] = showGridLines;
    table['firstRowAsHeader'] = firstRowAsHeader;
    table['gridStyle'] = gridStyle;

    final columns = (table['columns'] as List<dynamic>?) ?? const [];
    for (var i = 0; i < columns.length && i < columnWidths.length; i++) {
      final column = columns[i];
      if (column is Map<String, dynamic>) {
        column['width'] = _widthFromString(columnWidths[i]);
      }
    }

    _patchHighlightCell(table, cellMinHeight: cellMinHeight, cellStyle: cellStyle);
    return patched;
  }

  void _patchHighlightCell(
    Map<String, dynamic> table, {
    required double cellMinHeight,
    required String cellStyle,
  }) {
    final rows = table['rows'] as List<dynamic>?;
    if (rows == null || rows.length <= _highlightRow) {
      return;
    }
    final row = rows[_highlightRow];
    if (row is! Map<String, dynamic>) {
      return;
    }
    final cells = row['cells'] as List<dynamic>?;
    if (cells == null || cells.length <= _highlightCol) {
      return;
    }
    final cell = cells[_highlightCol];
    if (cell is! Map<String, dynamic>) {
      return;
    }

    if (cellMinHeight <= 0) {
      cell.remove('minHeight');
    } else {
      cell['minHeight'] = '${cellMinHeight.round()}px';
    }

    if (cellStyle == 'none') {
      cell.remove('style');
    } else {
      cell['style'] = cellStyle;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Knobs must be read on every build before any early return so Widgetbook
    // registers them (same pattern as ChartKnobsPage).
    final defaults = _defaults ?? const TableKnobDefaults();

    final showGridLines = context.knobs.boolean(
      label: 'showGridLines',
      initialValue: defaults.showGridLines,
    );
    final firstRowAsHeader = context.knobs.boolean(
      label: 'firstRowAsHeader',
      initialValue: defaults.firstRowAsHeader,
    );
    final gridStyle = context.knobs.object.dropdown<String>(
      label: 'gridStyle',
      options: tableStyleOptions,
      initialOption: tableStyleOptions.contains(defaults.gridStyle)
          ? defaults.gridStyle
          : 'accent',
      labelBuilder: (value) => value,
    );

    final columnWidths = <String>[
      for (var i = 0; i < defaults.columnWidths.length; i++)
        context.knobs.object.dropdown<String>(
          label: 'column ${i + 1} width',
          options: tableWidthOptions,
          initialOption: tableWidthOptions.contains(defaults.columnWidths[i])
              ? defaults.columnWidths[i]
              : 'stretch',
          labelBuilder: (value) => value,
        ),
    ];

    final cellMinHeight = context.knobs.double.slider(
      label: 'highlighted cell minHeight (px)',
      initialValue: 0,
      max: 200,
      divisions: 20,
    );
    final cellStyle = context.knobs.object.dropdown<String>(
      label: 'highlighted cell style',
      options: <String>['none', ...tableStyleOptions],
      initialOption: 'good',
      labelBuilder: (value) => value,
    );

    final baseCardMap = _baseCardMap;
    if (baseCardMap == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final cardMap = _cloneAndPatch(
      showGridLines: showGridLines,
      firstRowAsHeader: firstRowAsHeader,
      gridStyle: gridStyle,
      columnWidths: columnWidths,
      cellMinHeight: cellMinHeight,
      cellStyle: cellStyle,
    );

    return SelectionArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(8),
        child: RawAdaptiveCard.fromMap(
          key: _cardKey,
          map: cardMap,
          cardTypeRegistry: widgetbookCardTypeRegistry,
          hostConfigs: HostConfigs(),
          showDebugJson: true,
        ),
      ),
    );
  }
}
