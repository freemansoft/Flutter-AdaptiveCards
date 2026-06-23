import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/cards/inputs/date.dart';
import 'package:flutter_adaptive_cards_fs/src/models/action_invoke.dart';
import 'package:flutter_adaptive_cards_fs/src/riverpod/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'utils/test_utils.dart';

void main() {
  testWidgets('Activity Update test', (tester) async {
    SubmitActionInvoke? submitted;
    final Widget widget = getTestWidgetFromPath(
      path: 'example1.json',
      onSubmit: (invoke) => submitted = invoke,
    );

    await tester.pumpWidget(widget);
    // this is so that the async loading of the card is completed
    await tester.pumpAndSettle();

    // TextBlock text and FactSet values render as markdown (MarkdownBody ->
    // RichText), not plain Text widgets, so find.text only matches them when
    // findRichText is enabled.

    // "Matt Hidinger" appears twice: the author TextBlock and the
    // "Assigned to:" FactSet value.
    expect(find.text('Matt Hidinger', findRichText: true), findsNWidgets(2));

    expect(
      find.text(
        'Now that we have defined the main rules and features of'
        ' the format, we need to produce a schema and publish it to GitHub. '
        'The schema will be the starting point of our reference documentation.',
        findRichText: true,
      ),
      findsOneWidget,
    );

    expect(find.byType(Image), findsOneWidget);

    // The two buttons "Set due date" and "Comment"
    // other card is hidden
    expect(find.byType(ElevatedButton), findsNWidgets(2));
    expect(find.byType(AdaptiveDateInput), findsNWidgets(0));

    expect(find.widgetWithText(ElevatedButton, 'Set due date'), findsOneWidget);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Set due date'));
    await tester.pump();
    // should make this field appear
    expect(find.byType(AdaptiveDateInput), findsNWidgets(1));
    final textFieldFinder = find.byKey(const ValueKey('dueDate'));
    expect(textFieldFinder, findsOneWidget);

    // Set the date value the same way the platform picker does (via the
    // document overlay), submit the show-card's OK action, and verify the
    // collected input value reaches the host's onSubmit payload.
    final container = ProviderScope.containerOf(tester.element(textFieldFinder));
    container
        .read(adaptiveCardDocumentProvider.notifier)
        .setInputValue('dueDate', '2025-09-15');
    await tester.pump();

    expect(find.widgetWithText(ElevatedButton, 'OK'), findsOneWidget);

    final Widget button = tester.firstWidget(
      find.widgetWithText(ElevatedButton, 'OK'),
    );

    await tester.tap(find.byWidget(button));
    await tester.pump();
    expect(submitted, isNotNull);
    expect(submitted!.data['dueDate'], equals('2025-09-15'));

    await tester.tap(find.widgetWithText(ElevatedButton, 'Comment'));
    await tester.pump();
    expect(find.byType(ElevatedButton), findsNWidgets(3));

    expect(find.widgetWithText(ElevatedButton, 'OK'), findsOneWidget);

    // Also has OK widget but it's a different instance

    expect(find.byWidget(button), findsNothing);

    await tester.pump(
      const Duration(
        seconds: 1,
      ),
    ); // skip past any activity or animation
  });
}
