import 'package:flutter/foundation.dart';
import 'package:flutter_adaptive_template_fs/src/evaluator.dart';

void main() {
  final e = Evaluator({'price': 30, 'diff': -2});
  debugPrint(
    e.expand({
      'type': 'TextBlock',
      'text': r"${if(diff >= 0, '▲', '▼')} USD ${diff}",
    }),
  );
}
