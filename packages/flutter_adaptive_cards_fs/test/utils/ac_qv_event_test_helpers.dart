import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/cards/adaptive_card_element.dart';
import 'package:flutter_adaptive_cards_fs/src/riverpod/providers.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Finder get acQvEventScrollable => find.byType(Scrollable).first;

ProviderContainer _acQvEventContainer(WidgetTester tester) {
  return ProviderScope.containerOf(
    tester.element(find.byType(AdaptiveCardElement)),
  );
}

/// Opens the registration form on [ac-qv-event.json].
Future<void> revealAcQvEventRegistrationForm(WidgetTester tester) async {
  final register = find.text('Register');
  await tester.scrollUntilVisible(
    register.first,
    200,
    scrollable: acQvEventScrollable,
  );
  await tester.tap(register.first);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

/// Fills required registration fields except phone (first/last name are pre-filled).
Future<void> fillAcQvEventRegistrationPrerequisites(WidgetTester tester) async {
  _acQvEventContainer(
    tester,
  ).read(adaptiveCardDocumentProvider.notifier).setInputValue(
    'company_name',
    'Acme Corp',
  );
  await tester.pump();
}

Future<void> scrollToAcQvEventPhoneField(WidgetTester tester) async {
  final phoneField = find.byKey(generateWidgetKeyFromId('phone'));
  await tester.scrollUntilVisible(
    phoneField.first,
    200,
    scrollable: acQvEventScrollable,
  );
}

Future<void> tapAcQvEventSubmit(WidgetTester tester) async {
  final submit = find.text('Submit');
  await tester.scrollUntilVisible(
    submit.first,
    200,
    scrollable: acQvEventScrollable,
  );
  await tester.tap(submit.first);
  await tester.pump();
}
