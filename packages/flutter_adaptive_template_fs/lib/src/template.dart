import 'package:flutter_adaptive_template_fs/src/evaluator.dart';

///
class AdaptiveCardTemplate {
  /// constructor
  AdaptiveCardTemplate(this._payload);

  final Map<String, dynamic> _payload;

  /// expand (?) the template
  String expand(Map<String, dynamic> data) {
    final evaluator = Evaluator(data);
    return evaluator.expand(_payload);
  }
}
