import 'package:flutter_adaptive_cards_fs/src/utils/associated_inputs.dart';

class DataQuery {
  DataQuery({
    required this.dataset,
    this.count,
    this.skip,
    this.associatedInputs,
    this.parameters,
  });

  factory DataQuery.fromJson(Map<String, dynamic> json) {
    return DataQuery(
      dataset: json['dataset'] as String,
      count: json['count'] as int?,
      skip: json['skip'] as int?,
      associatedInputs: json['associatedInputs'] as String?,
      parameters: json['parameters'] as Map<String, dynamic>?,
    );
  }
  final String dataset;
  final int? count;
  final int? skip;
  final String? associatedInputs;

  /// Host extension (e.g. bound input values); not part of the core AC schema.
  final Map<String, dynamic>? parameters;

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
