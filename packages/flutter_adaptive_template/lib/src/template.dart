import 'package:flutter_adaptive_template/src/evaluator.dart';

class AdaptiveCardTemplate {
  final Map<String, dynamic> _payload;

  AdaptiveCardTemplate(this._payload);

  String expand(Map<String, dynamic> data) {
    final evaluator = Evaluator(data);
    return evaluator.expand(_payload);
  }
}
