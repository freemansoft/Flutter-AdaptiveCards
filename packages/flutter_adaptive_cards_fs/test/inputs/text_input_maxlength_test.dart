// Tests for `Input.Text` maxLength spec compliance.
//
// Scenarios are driven by test/samples/example8.json. Each Input.Text field
// in that file covers a distinct maxLength scenario:
//   SimpleVal    — no maxLength key         → no cap
//   UrlVal       — maxLength: 5             → capped at 5
//   EmailVal     — maxLength: 0             → no cap (0 = no limit)
//   TelVal       — maxLength: 1             → capped at 1
//   MultiLineVal — maxLength: -1            → no cap (negative = no limit)
//
// The card is rendered scrollable so the tall example8 content does not
// overflow the test viewport.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_adaptive_cards_fs/src/cards/inputs/text.dart';
import 'package:flutter_adaptive_cards_fs/src/utils/utils.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_utils.dart';

/// Returns the first element map in [body] whose `id` matches [id].
Map<String, dynamic> _fieldById(List<dynamic> body, String id) {
  return body.firstWhere(
        (e) => e is Map<String, dynamic> && e['id'] == id,
      )
      as Map<String, dynamic>;
}

void main() {
  late Map<String, dynamic> card;
  late List<dynamic> body;

  setUpAll(() {
    final raw = File('test/samples/example8.json').readAsStringSync();
    card = json.decode(raw) as Map<String, dynamic>;
    body = card['body'] as List<dynamic>;
  });

  // ---------------------------------------------------------------------------
  // Test 1: SimpleVal — no maxLength key → no cap.
  // ---------------------------------------------------------------------------
  testWidgets(
    'SimpleVal (no maxLength): 30-char input is not truncated',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        getTestWidgetFromMap(
          map: card,
          title: 'example8 maxLength tests',
          scrollable: true,
        ),
      );
      await tester.pumpAndSettle();

      final fieldMap = _fieldById(body, 'SimpleVal');
      const longText = 'abcdefghijklmnopqrstuvwxyz1234'; // 30 chars

      await tester.enterText(find.byKey(generateWidgetKey(fieldMap)), longText);
      await tester.pump();

      final state = tester.state<AdaptiveTextInputState>(
        find.byKey(generateAdaptiveWidgetKey(fieldMap)),
      );
      expect(
        state.controller.text.length,
        30,
        reason: 'Absent maxLength must impose no cap; all 30 chars retained',
      );
      expect(state.controller.text, longText);
    },
  );

  // ---------------------------------------------------------------------------
  // Test 2: UrlVal — maxLength: 5 → capped at 5.
  // ---------------------------------------------------------------------------
  testWidgets(
    'UrlVal (maxLength: 5): 8-char input is capped at 5',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        getTestWidgetFromMap(
          map: card,
          title: 'example8 maxLength tests',
          scrollable: true,
        ),
      );
      await tester.pumpAndSettle();

      final fieldMap = _fieldById(body, 'UrlVal');

      await tester.enterText(
        find.byKey(generateWidgetKey(fieldMap)),
        'abcdefgh', // 8 chars
      );
      await tester.pump();

      final state = tester.state<AdaptiveTextInputState>(
        find.byKey(generateAdaptiveWidgetKey(fieldMap)),
      );
      expect(
        state.controller.text.length,
        5,
        reason: 'maxLength: 5 must cap input at 5 characters',
      );
      expect(state.controller.text, 'abcde');
    },
  );

  // ---------------------------------------------------------------------------
  // Test 3: UrlVal boundary — exactly 5 chars retained.
  // ---------------------------------------------------------------------------
  testWidgets(
    'UrlVal (maxLength: 5): exactly 5-char input is fully retained',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        getTestWidgetFromMap(
          map: card,
          title: 'example8 maxLength tests',
          scrollable: true,
        ),
      );
      await tester.pumpAndSettle();

      final fieldMap = _fieldById(body, 'UrlVal');

      await tester.enterText(
        find.byKey(generateWidgetKey(fieldMap)),
        'abcde', // exactly 5 chars
      );
      await tester.pump();

      final state = tester.state<AdaptiveTextInputState>(
        find.byKey(generateAdaptiveWidgetKey(fieldMap)),
      );
      expect(
        state.controller.text.length,
        5,
        reason: 'Entering exactly maxLength chars must retain all 5',
      );
      expect(state.controller.text, 'abcde');
    },
  );

  // ---------------------------------------------------------------------------
  // Test 4: EmailVal — maxLength: 0 → no cap.
  // ---------------------------------------------------------------------------
  testWidgets(
    'EmailVal (maxLength: 0): 30-char input is not truncated',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        getTestWidgetFromMap(
          map: card,
          title: 'example8 maxLength tests',
          scrollable: true,
        ),
      );
      await tester.pumpAndSettle();

      final fieldMap = _fieldById(body, 'EmailVal');
      const longText = 'abcdefghijklmnopqrstuvwxyz1234'; // 30 chars

      await tester.enterText(find.byKey(generateWidgetKey(fieldMap)), longText);
      await tester.pump();

      final state = tester.state<AdaptiveTextInputState>(
        find.byKey(generateAdaptiveWidgetKey(fieldMap)),
      );
      expect(
        state.controller.text.length,
        30,
        reason: 'maxLength: 0 means no limit; all 30 chars must be retained',
      );
      expect(state.controller.text, longText);
    },
  );

  // ---------------------------------------------------------------------------
  // Test 5: TelVal — maxLength: 1 → capped at 1.
  // ---------------------------------------------------------------------------
  testWidgets(
    'TelVal (maxLength: 1): "ab" input is capped to "a"',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        getTestWidgetFromMap(
          map: card,
          title: 'example8 maxLength tests',
          scrollable: true,
        ),
      );
      await tester.pumpAndSettle();

      final fieldMap = _fieldById(body, 'TelVal');

      await tester.enterText(find.byKey(generateWidgetKey(fieldMap)), 'ab');
      await tester.pump();

      final state = tester.state<AdaptiveTextInputState>(
        find.byKey(generateAdaptiveWidgetKey(fieldMap)),
      );
      expect(
        state.controller.text.length,
        1,
        reason: 'maxLength: 1 must cap input at 1 character',
      );
      expect(state.controller.text, 'a');
    },
  );

  // ---------------------------------------------------------------------------
  // Test 6: MultiLineVal — maxLength: -1 → no cap.
  // ---------------------------------------------------------------------------
  testWidgets(
    'MultiLineVal (maxLength: -1): 30-char input is not truncated',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        getTestWidgetFromMap(
          map: card,
          title: 'example8 maxLength tests',
          scrollable: true,
        ),
      );
      await tester.pumpAndSettle();

      final fieldMap = _fieldById(body, 'MultiLineVal');
      const longText = 'abcdefghijklmnopqrstuvwxyz1234'; // 30 chars

      await tester.enterText(find.byKey(generateWidgetKey(fieldMap)), longText);
      await tester.pump();

      final state = tester.state<AdaptiveTextInputState>(
        find.byKey(generateAdaptiveWidgetKey(fieldMap)),
      );
      expect(
        state.controller.text.length,
        30,
        reason:
            'maxLength: -1 is non-positive; no formatter installed, '
            'all 30 chars must be retained',
      );
      expect(state.controller.text, longText);
    },
  );
}
