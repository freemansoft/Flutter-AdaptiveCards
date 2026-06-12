import 'package:flutter/foundation.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/date_time_utils.dart';

/// Fact model for AdaptiveCards FactSet element
///
/// * https://adaptivecards.io/explorer/FactSet.html
/// * https://adaptivecards.io/explorer/Fact.html
@immutable
class Fact {
  /// One FactSet row; [title] is the label column, [value] the value column.
  const Fact({
    required this.title,
    required this.value,
  });

  /// Parses a FactSet fact from card JSON; expands DATE/TIME templates in
  /// strings.
  factory Fact.fromJson(Map<String, dynamic> json) {
    return Fact(
      title: DateTimeUtils.formatText(json['title'] as String? ?? ''),
      value: DateTimeUtils.formatText(json['value'] as String? ?? ''),
    );
  }

  /// FactSet label column.
  final String title;

  /// FactSet value column (displayed and submitted text).
  final String value;

  /// Serializes for `RawAdaptiveCardState.setFacts` overlays and resolved JSON.
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'value': value,
    };
  }

  @override
  String toString() => 'Fact(title: $title, value: $value)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Fact && other.title == title && other.value == value;
  }

  @override
  int get hashCode => Object.hash(title, value);
}

/// Parses a card JSON `facts` array; returns empty when invalid.
List<Fact> factsFromJsonList(Object? raw) {
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((e) => Fact.fromJson(Map<String, dynamic>.from(e)))
      .toList();
}

/// Serializes facts for overlay merge boundaries.
List<Map<String, dynamic>> factsToJsonList(List<Fact> facts) =>
    facts.map((f) => f.toJson()).toList();
