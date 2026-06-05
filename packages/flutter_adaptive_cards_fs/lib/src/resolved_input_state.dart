import 'package:flutter/foundation.dart';

/// Merged baseline + overlay view of one input element from the resolved
/// element provider for that id.
@immutable
class ResolvedInputState {
  /// Creates a resolved input snapshot from a merged element map.
  const ResolvedInputState(this.map);

  /// Baseline JSON merged with runtime overlays for one input id.
  final Map<String, dynamic> map;

  /// Raw resolved `"value"` (overlay or baseline).
  Object? get valueRaw => map['value'];

  /// Resolved `"value"` as a display/submit string (`''` when absent).
  String get valueAsString {
    final raw = map['value'];
    if (raw == null) return '';
    final string = raw.toString();
    return string == 'null' ? '' : string;
  }

  /// Resolved `"label"`.
  String? get label => map['label'] as String?;

  /// Resolved placeholder (explicit placeholder or label fallback).
  String get placeholder => effectivePlaceholder(map);

  /// Resolved `"isRequired"`.
  bool get isRequired => map['isRequired'] as bool? ?? false;

  /// Resolved `"errorMessage"`.
  String? get errorMessage => map['errorMessage'] as String?;

  /// Host overlay / baseline `"isInvalid"`.
  bool get isInvalid => map['isInvalid'] == true;

  /// Placeholder fallback used by input widgets and resolved merge.
  static String effectivePlaceholder(Map<String, dynamic> map) {
    return map['placeholder'] as String? ?? map['label'] as String? ?? '';
  }
}
