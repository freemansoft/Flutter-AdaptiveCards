import 'package:flutter_adaptive_cards_fs/src/hostconfig/fallback_configs.dart';
import 'package:flutter_adaptive_cards_fs/src/responsive/width_bucket.dart';

/// HostConfig `hostWidthBreakpoints` section: the pixel upper bounds that
/// separate the responsive [WidthBucket]s.
///
/// Each value is the exclusive upper bound of a bucket (`width < veryNarrowMax`
/// is `veryNarrow`, and so on). Hosts may override these; absent values fall
/// back to the Adaptive Cards spec defaults.
class HostWidthsConfig {
  /// Creates breakpoints from explicit pixel upper bounds.
  HostWidthsConfig({
    required this.veryNarrowMax,
    required this.narrowMax,
    required this.standardMax,
  });

  /// Parses `hostWidthBreakpoints` from HostConfig JSON, defaulting any missing
  /// key to the corresponding spec default in [FallbackConfigs.hostWidthsConfig]
  /// (the single source of truth for the default breakpoints).
  factory HostWidthsConfig.fromJson(Map<String, dynamic> json) {
    final defaults = FallbackConfigs.hostWidthsConfig;
    return HostWidthsConfig(
      veryNarrowMax:
          (json['veryNarrow'] as num?)?.toInt() ?? defaults.veryNarrowMax,
      narrowMax: (json['narrow'] as num?)?.toInt() ?? defaults.narrowMax,
      standardMax: (json['standard'] as num?)?.toInt() ?? defaults.standardMax,
    );
  }

  /// Upper bound (exclusive) of the `veryNarrow` bucket.
  final int veryNarrowMax;

  /// Upper bound (exclusive) of the `narrow` bucket.
  final int narrowMax;

  /// Upper bound (exclusive) of the `standard` bucket; at or above is `wide`.
  final int standardMax;

  /// Resolves a [WidthBucket] for [width] using [config] (or spec defaults when
  /// [config] is null).
  static WidthBucket resolveBucket(HostWidthsConfig? config, double width) {
    final c = config ?? FallbackConfigs.hostWidthsConfig;
    if (width < c.veryNarrowMax) return WidthBucket.veryNarrow;
    if (width < c.narrowMax) return WidthBucket.narrow;
    if (width < c.standardMax) return WidthBucket.standard;
    return WidthBucket.wide;
  }
}
