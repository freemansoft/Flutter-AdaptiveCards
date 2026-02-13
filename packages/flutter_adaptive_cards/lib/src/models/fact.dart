import 'package:flutter/foundation.dart';

/// Fact model for AdaptiveCards FactSet element
///
/// * https://adaptivecards.io/explorer/FactSet.html
/// * https://adaptivecards.io/explorer/Fact.html
@immutable
class Fact {
  const Fact({
    required this.title,
    required this.value,
  });

  /// Creates a Fact from JSON map
  factory Fact.fromJson(Map<String, dynamic> json) {
    return Fact(
      title: json['title'] as String? ?? '',
      value: json['value'] as String? ?? '',
    );
  }

  /// The title of the fact
  final String title;

  /// The value of the fact
  final String value;

  /// Converts Fact to JSON map
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
