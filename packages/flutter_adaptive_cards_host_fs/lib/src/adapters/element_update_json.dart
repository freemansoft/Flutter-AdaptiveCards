import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';

/// Parses one element patch object from PlainJson invoke responses.
AdaptiveElementUpdate elementUpdateFromJson(Map<String, dynamic> json) {
  final id = json['id'] as String;
  List<Choice>? choices;
  final rawChoices = json['choices'];
  if (rawChoices is List) {
    choices = choicesFromJsonList(rawChoices);
  }

  return AdaptiveElementUpdate(
    id: id,
    isVisible: json['isVisible'] as bool?,
    value: json.containsKey('value') ? json['value'] : null,
    errorMessage: json['errorMessage'] as String?,
    isInvalid: json['isInvalid'] as bool?,
    isRequired: json['isRequired'] as bool?,
    url: json['url'] as String?,
    text: json['text'] as String?,
    label: json['label'] as String?,
    placeholder: json['placeholder'] as String?,
    choices: choices,
    clearValue: json['clearValue'] == true,
    clearError: json['clearError'] == true,
    clearChoices: json['clearChoices'] == true,
    clearText: json['clearText'] == true,
    clearIsRequired: json['clearIsRequired'] == true,
    clearUrl: json['clearUrl'] == true,
    clearLabel: json['clearLabel'] == true,
    clearPlaceholder: json['clearPlaceholder'] == true,
    clearFacts: json['clearFacts'] == true,
  );
}
