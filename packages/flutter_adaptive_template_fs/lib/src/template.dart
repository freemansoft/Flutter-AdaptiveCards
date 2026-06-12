import 'package:flutter_adaptive_template_fs/src/evaluator.dart';

/// Holds a templated Adaptive Card payload; call [expand] with runtime data to
/// produce renderable card JSON.
class AdaptiveCardTemplate {
  /// Wraps a parsed template map (from JSON) before expansion.
  AdaptiveCardTemplate(this._payload);

  final Map<String, dynamic> _payload;

  /// Binds [data] into the template and returns expanded card JSON as a string
  /// ready for parsing/rendering.
  String expand(Map<String, dynamic> data) {
    final evaluator = Evaluator(data);
    return evaluator.expand(_payload);
  }
}
