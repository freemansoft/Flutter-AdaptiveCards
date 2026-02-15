import 'package:flutter/foundation.dart';

/// Choice model for AdaptiveCards Input.ChoiceSet element
///
/// * https://adaptivecards.io/explorer/Input.ChoiceSet.html
/// * https://adaptivecards.io/explorer/Input.Choice.html
@immutable
class Choice {
  const Choice({
    required this.title,
    required this.value,
  });

  /// Creates a Choice from JSON map
  factory Choice.fromJson(Map<String, dynamic> json) {
    return Choice(
      title: json['title'] as String? ?? '',
      value: json['value']?.toString() ?? '',
    );
  }

  /// Display text for the choice
  final String title;

  /// The raw value for the choice (what gets submitted)
  final String value;

  /// Converts Choice to JSON map
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
