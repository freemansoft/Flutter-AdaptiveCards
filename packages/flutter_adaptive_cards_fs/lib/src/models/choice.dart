import 'package:flutter/foundation.dart';

/// Choice model for AdaptiveCards Input.ChoiceSet element
///
/// * https://adaptivecards.io/explorer/Input.ChoiceSet.html
/// * https://learn.microsoft.com/en-us/adaptive-cards/schema-explorer/input-choice-set
/// * https://adaptivecards.io/explorer/Input.Choice.html
/// * https://learn.microsoft.com/en-us/adaptive-cards/schema-explorer/input-choice
@immutable
class Choice {
  /// One ChoiceSet option; [title] is shown, [value] is submitted.
  const Choice({
    required this.title,
    required this.value,
  });

  /// Parses an Adaptive Cards `Input.Choice` object from card JSON.
  factory Choice.fromJson(Map<String, dynamic> json) {
    return Choice(
      title: json['title'] as String? ?? '',
      value: json['value']?.toString() ?? '',
    );
  }

  /// Label shown in the ChoiceSet UI.
  final String title;

  /// Submitted value when this choice is selected (not the display title).
  final String value;

  /// Serializes for overlay updates and resolved element JSON.
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'value': value,
    };
  }

  @override
  String toString() => 'Choice(title: $title, value: $value)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Choice && other.title == title && other.value == value;
  }

  @override
  int get hashCode => Object.hash(title, value);
}

/// Parses a card JSON `choices` array into [Choice] list; returns empty when
/// invalid.
List<Choice> choicesFromJsonList(Object? raw) {
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((e) => Choice.fromJson(Map<String, dynamic>.from(e)))
      .toList();
}

/// Serializes choices for runtime overlay / resolved JSON boundaries.
List<Map<String, dynamic>> choicesToJsonList(List<Choice> choices) =>
    choices.map((c) => c.toJson()).toList();
