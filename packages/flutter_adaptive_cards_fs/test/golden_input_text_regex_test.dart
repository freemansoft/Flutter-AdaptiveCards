import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';
import 'package:flutter_test/flutter_test.dart';

import 'utils/ac_qv_event_test_helpers.dart';
import 'utils/test_utils.dart';

void configureTestView() {
  RendererBinding.instance.renderViews.first.configuration =
      TestViewConfiguration.fromView(
        size: const Size(500, 700),
        view: PlatformDispatcher.instance.implicitView!,
      );
}

void main() {
  testWidgets('ac-qv-event phone regex invalid golden', (tester) async {
    configureTestView();

    const key = ValueKey('paint');

    await tester.pumpWidget(
      getTestWidgetFromPath(
        path: 'ac-qv-event.json',
        key: key,
        listView: true,
        scrollable: true,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await revealAcQvEventRegistrationForm(tester);
    await fillAcQvEventRegistrationPrerequisites(tester);
    await scrollToAcQvEventPhoneField(tester);

    await tester.enterText(
      find.byKey(generateWidgetKeyFromId('phone')).first,
      'AAA',
    );
    await tester.pump();

    await tapAcQvEventSubmit(tester);

    await tester.scrollUntilVisible(
      find.text('Enter a valid phone number.').first,
      200,
      scrollable: acQvEventScrollable,
    );
    await tester.pump();

    await expectLater(
      find.byKey(key),
      matchesGoldenFile(getGoldenPath('ac-qv-event_phone_invalid.png')),
    );
  }, tags: ['golden']);
}
