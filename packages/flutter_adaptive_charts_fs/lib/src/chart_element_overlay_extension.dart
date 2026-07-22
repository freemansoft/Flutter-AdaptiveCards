import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';

/// Extension id registered on [CardTypeRegistry.overlayExtensions].
const chartOverlayExtensionId = 'charts';

/// Whitelisted chart chrome keys merged from overlay payload `chartProperties`.
const chartPropertyKeys = {
  'title',
  'xAxisTitle',
  'yAxisTitle',
  'showBarValues',
  'showLegend',
  'colorSet',
  'value',
  'min',
  'max',
  'subLabel',
  'valueFormat',
  'showMinMax',
};

/// Overlay merge hook for `Chart.*` element types.
class ChartElementOverlayExtension extends ElementOverlayExtension {
  /// Creates the chart overlay extension hook.
  const ChartElementOverlayExtension();

  /// Shared chart overlay extension instance for registry injection.
  static const instance = ChartElementOverlayExtension();

  @override
  String get id => chartOverlayExtensionId;

  @override
  Set<String> get overlayPatchKeys => const {
    'data',
    'chartData',
    'chartProperties',
    'clearChartData',
    'clearChartProperties',
    'clearPayload',
  };

  @override
  bool appliesTo(String elementType) => elementType.startsWith('Chart.');

  @override
  void mergeResolved(
    Map<String, dynamic> merged,
    Map<String, dynamic> payload,
  ) {
    final chartData = payload['chartData'];
    if (chartData is List) {
      merged['data'] = List<dynamic>.from(chartData);
    }
    final chartProperties = payload['chartProperties'];
    if (chartProperties is Map) {
      for (final entry in chartProperties.entries) {
        if (chartPropertyKeys.contains(entry.key)) {
          merged[entry.key] = entry.value;
        }
      }
    }
  }

  @override
  Map<String, dynamic> mergePayload({
    required Map<String, dynamic> current,
    required Map<String, dynamic> patch,
  }) {
    final next = Map<String, dynamic>.from(current);
    if (patch['clearPayload'] == true) {
      return const {};
    }
    if (patch['clearChartData'] == true) {
      next.remove('chartData');
    }
    if (patch['clearChartProperties'] == true) {
      next.remove('chartProperties');
    }
    if (patch['chartData'] is List) {
      next['chartData'] = List<dynamic>.from(patch['chartData'] as List);
    }
    if (patch['data'] is List) {
      next['chartData'] = List<dynamic>.from(patch['data'] as List);
    }
    if (patch['chartProperties'] is Map) {
      final merged = Map<String, dynamic>.from(
        (next['chartProperties'] as Map?)?.map(
              (key, value) => MapEntry(key.toString(), value),
            ) ??
            const {},
      );
      for (final entry in Map<String, dynamic>.from(
        patch['chartProperties'] as Map,
      ).entries) {
        if (chartPropertyKeys.contains(entry.key)) {
          merged[entry.key] = entry.value;
        }
      }
      next['chartProperties'] = merged;
    }
    return next;
  }

  @override
  Map<String, dynamic>? patchFromHostMap(Map<String, dynamic> hostPatch) {
    final result = <String, dynamic>{};
    if (hostPatch['clearChartData'] == true) {
      result['clearChartData'] = true;
    }
    if (hostPatch['clearChartProperties'] == true) {
      result['clearChartProperties'] = true;
    }
    if (hostPatch['clearPayload'] == true) {
      result['clearPayload'] = true;
    }
    if (hostPatch['data'] is List) {
      result['chartData'] = List<dynamic>.from(hostPatch['data'] as List);
    }
    if (hostPatch['chartProperties'] is Map) {
      result['chartProperties'] = Map<String, dynamic>.from(
        hostPatch['chartProperties'] as Map,
      );
    }
    return result.isEmpty ? null : result;
  }
}

/// Typed host helpers for chart overlay APIs on [RawAdaptiveCardState].
extension ChartOverlayHost on RawAdaptiveCardState {
  /// Replaces effective chart `"data"` for [id].
  void setChartData(String id, List<dynamic> data) {
    patchExtensionOverlay(
      id,
      chartOverlayExtensionId,
      {'chartData': data},
    );
  }

  /// Clears chart data overlay for [id].
  void clearChartData(String id) {
    patchExtensionOverlay(
      id,
      chartOverlayExtensionId,
      {'clearChartData': true},
    );
  }

  /// Shallow-patches whitelisted chart chrome keys on [id].
  void patchChartProperties(String id, Map<String, dynamic> properties) {
    patchExtensionOverlay(
      id,
      chartOverlayExtensionId,
      {'chartProperties': properties},
    );
  }

  /// Clears chart property overlay for [id].
  void clearChartProperties(String id) {
    patchExtensionOverlay(
      id,
      chartOverlayExtensionId,
      {'clearChartProperties': true},
    );
  }
}
