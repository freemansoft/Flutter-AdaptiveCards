// This file keeps its execution-trace comments and long test names verbatim:
// wrapping the FIFO-ordering diagrams to 80 columns would obscure them.
// ignore_for_file: lines_longer_than_80_chars
//
// Regression test for the stale-echo bug in listenForResolvedValueChanges.
//
// FIX STRATEGY (post-frame FIFO ordering): Register an "IME advance" post-frame
// callback FIRST, then trigger a resolved-value change so the stale-echo
// callback is queued AFTER it. Flutter guarantees FIFO post-frame ordering, so:
//     [1] advance callback runs: controller → 'ab'/offset:1; doc → 'ab'
//     [2] stale-echo callback runs:
//         BUG: captured stale value clobbers controller and resets selection
//         FIX: reads latest resolved value ('ab') → controller already 'ab' → no-op
// This test FAILS before the fix and PASSES after.
import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/src/cards/inputs/number.dart';
import 'package:flutter_adaptive_cards_fs/src/cards/inputs/text.dart';
import 'package:flutter_adaptive_cards_fs/src/flutter_raw_adaptive_card.dart';
import 'package:flutter_adaptive_cards_fs/src/riverpod/providers.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

void main() {
  // ---------------------------------------------------------------------------
  // The key discriminating test. This MUST FAIL before the fix and PASS after.
  //
  // Setup: Establish doc='a', then register an "IME advance" post-frame
  // callback that moves controller and doc to 'ab'/offset:1. Then call
  // setInputValue('') to force ref.listen to fire — queuing the stale-echo
  // callback AFTER the advance. [1] advance callback: controller →
  // 'ab'/offset:1; doc notifier → 'ab' [2] stale-echo callback:
  //       BUG (captured ''): controller 'ab' ≠ '' → clobbers text + resets cursor
  //       FIX (reads latest 'ab'): controller 'ab' == 'ab' → no-op, selection kept
  // ---------------------------------------------------------------------------

  testWidgets(
    'fast-typing: stale post-frame echo is no-op with fix — MUST FAIL before fix',
    (WidgetTester tester) async {
      final Map<String, dynamic> map = {
        'type': 'AdaptiveCard',
        'body': [
          {
            'type': 'Input.Text',
            'id': 't',
            'label': 'Password',
            'maxLength': 100,
          },
        ],
      };

      await tester.pumpWidget(
        getTestWidgetFromMap(map: map, title: 'fast typing test'),
      );
      await tester.pumpAndSettle();

      final textMap = map['body'][0] as Map<String, dynamic>;
      final inputFinder = find.byKey(generateWidgetKey(textMap));
      final inputState = tester.state<AdaptiveTextInputState>(
        find.byType(AdaptiveTextInput),
      );
      final controller = inputState.controller;
      final container = ProviderScope.containerOf(tester.element(inputFinder));

      // Step 1: Establish doc='a', controller='a'.
      // Use cascade on the notifier assignment so the first call is chained.
      final notifier = container.read(adaptiveCardDocumentProvider.notifier)
        ..setInputValue('t', 'a');
      await tester.pump();
      expect(controller.text, 'a');

      // Step 2: Register the "IME advances" post-frame callback. This simulates
      // the user typing the next character BEFORE the post-frame callbacks
      // drain: controller advances to 'ab' at offset:1 AND the doc is also
      // advanced to 'ab' (as the IME would cause via controller listener).
      //
      // IMPORTANT: We register this BEFORE setInputValue below so it fires
      // BEFORE the stale-echo post-frame callback (FIFO ordering).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Simulate IME: controller becomes 'ab' with cursor at offset 1.
        // _isUpdatingFromDocument is false at this point, so the controller
        // addListener fires and updates doc='ab'.
        controller.value = const TextEditingValue(
          text: 'ab',
          selection: TextSelection.collapsed(offset: 1),
        );
      });

      // Step 3: Trigger a doc state change to a DIFFERENT value (empty) so that
      // ref.listen fires with a value that differs from the current doc.
      // This creates the stale capture: the callback captures '' while the doc
      // will later be advanced to 'ab' by the step 2 callback.
      notifier.setInputValue('t', '');

      // Step 4: pump() — the frame runs: a. Riverpod flush:
      // resolvedElementProvider 'a' → '' (doc is now '')
      //      ref.listen fires: previous?['value']='a', next?['value']='' → differ
      //      OLD: addPostFrameCallback(onDocumentValueChanged(capturedValue=''))
      //      NEW: addPostFrameCallback(onDocumentValueChanged(readResolvedInput().valueRaw))
      // b. Post-frame callbacks fire in FIFO order:
      //      [1] "IME advances" callback: controller → 'ab'/offset:1; doc → 'ab'
      //      [2] stale-echo callback:
      //          OLD: onDocumentValueChanged('') → controller='ab' ≠ '' → SETS ''
      //               → selection CLOBBERED to -1, text clobbered to '' ← BUG
      //          NEW: onDocumentValueChanged(readResolvedInput().valueRaw)
      //               = onDocumentValueChanged('ab') (doc was restored to 'ab')
      //               → controller='ab' == 'ab' → NO-OP → selection preserved ← FIX
      await tester.pump();

      // With the FIX: selection is preserved at offset:1; text is 'ab'.
      // With the BUG: selection is -1 (clobbered); text is '' (clobbered).
      expect(
        controller.selection.baseOffset,
        1,
        reason:
            'stale echo must not clobber cursor; fix reads latest value so echo is no-op',
      );
      expect(
        controller.text,
        'ab',
        reason: 'stale echo must not clobber text; fix reads latest value',
      );
    },
  );

  // ---------------------------------------------------------------------------
  // Regression guard 1: External programmatic doc change must still sync
  // controller.
  // ---------------------------------------------------------------------------
  testWidgets(
    'fast-typing: external programmatic value change still syncs controller',
    (WidgetTester tester) async {
      final Map<String, dynamic> map = {
        'type': 'AdaptiveCard',
        'body': [
          {
            'type': 'Input.Text',
            'id': 'ext',
            'label': 'External',
            'maxLength': 100,
          },
        ],
      };

      await tester.pumpWidget(
        getTestWidgetFromMap(map: map, title: 'external sync test'),
      );
      await tester.pumpAndSettle();

      final textMap = map['body'][0] as Map<String, dynamic>;
      final inputFinder = find.byKey(generateWidgetKey(textMap));
      final inputState = tester.state<AdaptiveTextInputState>(
        find.byType(AdaptiveTextInput),
      );
      final controller = inputState.controller;
      final container = ProviderScope.containerOf(tester.element(inputFinder));

      // Drive an external update from empty → 'hello'.
      final notifier = container.read(adaptiveCardDocumentProvider.notifier)
        ..setInputValue('ext', 'hello');
      await tester.pump();

      expect(
        controller.text,
        'hello',
        reason: 'external programmatic value change must still sync controller',
      );

      // Drive a second change to a different value.
      notifier.setInputValue('ext', 'world');
      await tester.pump();

      expect(controller.text, 'world');
    },
  );

  // ---------------------------------------------------------------------------
  // Regression guard 2: Sequential external changes sync correctly (each change
  // per pump so ref.listen fires for each transition).
  // ---------------------------------------------------------------------------
  testWidgets(
    'fast-typing: sequential external doc changes each update the controller',
    (WidgetTester tester) async {
      final Map<String, dynamic> map = {
        'type': 'AdaptiveCard',
        'body': [
          {
            'type': 'Input.Text',
            'id': 'seq',
            'label': 'Sequential',
            'maxLength': 100,
          },
        ],
      };

      await tester.pumpWidget(
        getTestWidgetFromMap(map: map, title: 'sequential test'),
      );
      await tester.pumpAndSettle();

      final textMap = map['body'][0] as Map<String, dynamic>;
      final inputFinder = find.byKey(generateWidgetKey(textMap));
      final inputState = tester.state<AdaptiveTextInputState>(
        find.byType(AdaptiveTextInput),
      );
      final controller = inputState.controller;
      final container = ProviderScope.containerOf(tester.element(inputFinder));
      final notifier = container.read(adaptiveCardDocumentProvider.notifier);

      for (final value in ['a', 'ab', 'abc', 'ab', 'a', '']) {
        notifier.setInputValue('seq', value);
        await tester.pump();
        expect(
          controller.text,
          value,
          reason: 'controller must track doc value "$value"',
        );
      }
    },
  );

  // ---------------------------------------------------------------------------
  // Regression guard 3: RawAdaptiveCardState.documentContainer.setInputValue.
  // ---------------------------------------------------------------------------
  testWidgets(
    'fast-typing: RawAdaptiveCard.documentContainer.setInputValue syncs controller',
    (WidgetTester tester) async {
      final Map<String, dynamic> map = {
        'type': 'AdaptiveCard',
        'body': [
          {
            'type': 'Input.Text',
            'id': 'host',
            'label': 'Host driven',
            'maxLength': 100,
          },
        ],
      };

      await tester.pumpWidget(
        getTestWidgetFromMap(map: map, title: 'host driven test'),
      );
      await tester.pumpAndSettle();

      final cardState = tester.state<RawAdaptiveCardState>(
        find.byType(RawAdaptiveCard),
      );
      final inputState = tester.state<AdaptiveTextInputState>(
        find.byType(AdaptiveTextInput),
      );
      final controller = inputState.controller;

      cardState.documentContainer!
          .read(adaptiveCardDocumentProvider.notifier)
          .setInputValue('host', 'from host');
      await tester.pump();

      expect(controller.text, 'from host');
    },
  );

  // ---------------------------------------------------------------------------
  // Input.Number parallel discriminating test.
  // AdaptiveNumberInputState uses the same AdaptiveInputMixin and the same
  // onDocumentValueChanged guard (controller.text == next → no-op).  This test
  // proves the stale-echo fix applies equally to number inputs.
  // ---------------------------------------------------------------------------
  testWidgets(
    'fast-typing: Input.Number stale post-frame echo is no-op with fix',
    (WidgetTester tester) async {
      final Map<String, dynamic> map = {
        'type': 'AdaptiveCard',
        'body': [
          {
            'type': 'Input.Number',
            'id': 'n',
            'label': 'Count',
            'min': 0,
            'max': 100,
          },
        ],
      };

      await tester.pumpWidget(
        getTestWidgetFromMap(map: map, title: 'number fast typing test'),
      );
      await tester.pumpAndSettle();

      final numMap = map['body'][0] as Map<String, dynamic>;
      final inputFinder = find.byKey(generateWidgetKey(numMap));
      final inputState = tester.state<AdaptiveNumberInputState>(
        find.byType(AdaptiveNumberInput),
      );
      final controller = inputState.controller;
      final container = ProviderScope.containerOf(tester.element(inputFinder));

      // Establish doc='5', controller='5'.
      final notifier = container.read(adaptiveCardDocumentProvider.notifier)
        ..setInputValue('n', '5');
      await tester.pump();
      expect(controller.text, '5');

      // Register "IME advances" callback FIRST (FIFO ordering):
      // simulates user typing more digits → controller advances to '50'/offset:1
      // and doc is also updated to '50' via the controller addListener.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.value = const TextEditingValue(
          text: '50',
          selection: TextSelection.collapsed(offset: 1),
        );
      });

      // Trigger a doc state change to '' so ref.listen fires and queues the
      // stale-echo callback AFTER the advance callback.
      notifier.setInputValue('n', '');

      // pump() — post-frame FIFO:
      //   [1] advance: controller → '50'/offset:1; doc → '50'
      //   [2] stale-echo:
      //       BUG (captured ''): controller '50' ≠ '' → clobbers text + cursor
      //       FIX (reads latest '50'): controller '50' == '50' → no-op
      await tester.pump();

      expect(
        controller.selection.baseOffset,
        1,
        reason:
            'stale echo must not clobber cursor on Input.Number; fix is a no-op',
      );
      expect(
        controller.text,
        '50',
        reason: 'stale echo must not clobber text on Input.Number',
      );
    },
  );
}
