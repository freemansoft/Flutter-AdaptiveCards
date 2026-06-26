import 'package:flutter_adaptive_cards_fs/src/utils/associated_inputs.dart';

/// Parsed `Data.Query` object from `choices.data` on `Input.ChoiceSet`.
///
/// See https://adaptivecards.io/explorer/Data.Query.html
/// See https://learn.microsoft.com/en-us/adaptive-cards/schema-explorer/data-query
class DataQuery {
  /// Creates a data query for the given [dataset] and optional paging fields.
  DataQuery({
    required this.dataset,
    this.count,
    this.skip,
    this.associatedInputs,
    this.parameters,
  });

  /// Parses a `Data.Query` map from card JSON.
  factory DataQuery.fromJson(Map<String, dynamic> json) {
    return DataQuery(
      dataset: json['dataset'] as String,
      count: json['count'] as int?,
      skip: json['skip'] as int?,
      associatedInputs: json['associatedInputs'] as String?,
      parameters: json['parameters'] as Map<String, dynamic>?,
    );
  }

  /// Target dataset name from `dataset`.
  final String dataset;

  /// Maximum rows to return from `count`.
  final int? count;

  /// Rows to skip from `skip`.
  final int? skip;

  /// How sibling inputs are merged: `auto`, `none`, etc.
  final String? associatedInputs;

  /// Host extension (e.g. bound input values); not part of the core AC schema.
  final Map<String, dynamic>? parameters;

  /// Returns a copy with sibling input values merged into [parameters].
  DataQuery withMergedSiblingInputs(
    Map<String, dynamic> siblingValues, {
    required String excludeInputId,
  }) {
    if (!shouldMergeAssociatedInputs(associatedInputs)) {
      return this;
    }
    return DataQuery(
      dataset: dataset,
      count: count,
      skip: skip,
      associatedInputs: associatedInputs,
      parameters: mergeSiblingInputParameters(
        siblingValues: siblingValues,
        excludeInputId: excludeInputId,
        existingParameters: parameters,
      ),
    );
  }

  /// Serializes this query back to Adaptive Cards JSON.
  Map<String, dynamic> toJson() {
    return {
      'type': 'Data.Query',
      'dataset': dataset,
      if (count != null) 'count': count,
      if (skip != null) 'skip': skip,
      if (associatedInputs != null) 'associatedInputs': associatedInputs,
      if (parameters != null) 'parameters': parameters,
    };
  }
}
