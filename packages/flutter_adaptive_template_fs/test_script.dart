import 'package:flutter/foundation.dart';
import 'package:flutter_adaptive_template_fs/src/evaluator.dart';
import 'package:flutter_adaptive_template_fs/src/expression_parser.dart';

void main() {
  final data = {'url': 'http://yelp.com'};
  try {
    final e = Evaluator(data);
    final ast = ExpressionParser.parse(
      'toUpper(substring(url, 7, length(url) - 7))',
    );
    debugPrint('AST: $ast');
    // evaluate it via reflection or indirectly
    final jsonTemplate = {
      'text': r'${toUpper(substring(url, 7, length(url) - 7))}',
    };
    final res = e.expand(jsonTemplate);
    debugPrint('Res: $res');
  } catch (e, st) {
    debugPrint('Error: $e \n $st');
  }
}
