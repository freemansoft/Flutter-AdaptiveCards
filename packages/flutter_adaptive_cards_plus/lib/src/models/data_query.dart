class DataQuery {
  DataQuery({
    required this.dataset,
    this.parameters,
  });

  factory DataQuery.fromJson(Map<String, dynamic> json) {
    return DataQuery(
      dataset: json['dataset'] as String,
      parameters: json['parameters'] as Map<String, dynamic>?,
    );
  }
  final String dataset;
  final Map<String, dynamic>? parameters;

  Map<String, dynamic> toJson() {
    return {
      'type': 'Data.Query',
      'dataset': dataset,
      if (parameters != null) 'parameters': parameters,
    };
  }
}
