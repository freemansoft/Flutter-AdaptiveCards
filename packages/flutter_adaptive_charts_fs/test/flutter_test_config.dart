import 'dart:async';

import 'package:flutter_adaptive_cards_test_support/flutter_adaptive_cards_test_support.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  await adaptiveCardsTestExecutable(testMain);
}
