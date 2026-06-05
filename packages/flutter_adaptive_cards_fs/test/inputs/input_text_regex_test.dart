import 'package:flutter_adaptive_cards_fs/src/riverpod/providers.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/ac_qv_event_test_helpers.dart';
import '../utils/test_utils.dart';

const _phoneErrorMessage = 'Enter a valid phone number.';

void main() {
  testWidgets('ac-qv-event phone regex shows error after invalid Submit', (
    WidgetTester tester,
  ) async {
    var submitCount = 0;

    await tester.pumpWidget(
      getTestWidgetFromPath(
        path: 'ac-qv-event.json',
        listView: true,
        scrollable: true,
        onSubmit: (_) => submitCount++,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(_phoneErrorMessage), findsNothing);

    await revealAcQvEventRegistrationForm(tester);
    await fillAcQvEventRegistrationPrerequisites(tester);
    await scrollToAcQvEventPhoneField(tester);

    await tester.enterText(
      find.byKey(generateWidgetKeyFromId('phone')).first,
      'AAA',
    );
    await tester.pump();

    expect(find.text(_phoneErrorMessage), findsNothing);

    await tapAcQvEventSubmit(tester);

    expect(submitCount, 0);
    expect(find.text(_phoneErrorMessage), findsOneWidget);

    final container = ProviderScope.containerOf(
      tester.element(find.byKey(generateWidgetKeyFromId('phone')).first),
    );
    expect(
      container.read(resolvedElementProvider('phone'))?['isInvalid'],
      isTrue,
    );
  });
}
