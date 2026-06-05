class DataQuery {
  DataQuery({
    required this.dataset,
    this.count,
    this.skip,
    this.parameters,
  });

  factory DataQuery.fromJson(Map<String, dynamic> json) {
    return DataQuery(
      dataset: json['dataset'] as String,
      count: json['count'] as int?,
      skip: json['skip'] as int?,
      parameters: json['parameters'] as Map<String, dynamic>?,
    );
  }
  final String dataset;
  final int? count;
  final int? skip;

  /// Host extension (e.g. bound input values); not part of the core AC schema.
  final Map<String, dynamic>? parameters;

  Map<String, dynamic> toJson() {
    return {
      'type': 'Data.Query',
      'dataset': dataset,
      if (count != null) 'count': count,
      if (skip != null) 'skip': skip,
      if (parameters != null) 'parameters': parameters,
    };
  }
}
