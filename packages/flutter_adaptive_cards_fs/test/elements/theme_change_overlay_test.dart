import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';
import 'package:flutter_test/flutter_test.dart';

// Regression tests for https://github.com/freemansoft/Flutter-AdaptiveCards
// (remove ValueKey<Brightness?> from ProviderScope in
// flutter_raw_adaptive_card.dart).
//
// Before the fix, a brightness change caused ProviderScope to receive a new
// ValueKey, which destroyed the AdaptiveCardDocumentNotifier and wiped all
// runtime overlays and typed input. These tests confirm both survive.

/// A wrapper whose theme can be switched after initial render without
/// replacing the AdaptiveCardsCanvas subtree.
Widget _themeControlledCard({
  required ValueNotifier<ThemeMode> themeMode,
  required Map<String, dynamic> map,
}) {
  return ValueListenableBuilder<ThemeMode>(
    valueListenable: themeMode,
    builder: (context, mode, _) => MaterialApp(
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: mode,
      home: Scaffold(
        body: AdaptiveCardsCanvas.map(
          content: map,
          hostConfigs: HostConfigs(),
          brightnessMode: AdaptiveCardBrightnessMode.auto,
          showDebugJson: false,
        ),
      ),
    ),
  );
}

void main() {
  group('overlay state survives theme brightness change', () {
    testWidgets('setText overlay is preserved after light→dark toggle', (
      WidgetTester tester,
    ) async {
      final themeMode = ValueNotifier(ThemeMode.light);
      addTearDown(themeMode.dispose);

      await tester.pumpWidget(
        _themeControlledCard(
          themeMode: themeMode,
          map: {
            'type': 'AdaptiveCard',
            'version': '1.5',
            'body': [
              {'type': 'TextBlock', 'id': 'status', 'text': 'Baseline'},
            ],
          },
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Baseline'), findsOneWidget);

      tester
          .state<RawAdaptiveCardState>(find.byType(RawAdaptiveCard))
          .setText('status', 'Overlay text');
      await tester.pump();
      expect(find.text('Overlay text'), findsOneWidget);

      // Trigger brightness change — previously caused ProviderScope key change
      // and destroyed AdaptiveCardDocumentNotifier, wiping all overlays.
      themeMode.value = ThemeMode.dark;
      await tester.pumpAndSettle();

      expect(find.text('Overlay text'), findsOneWidget);
      expect(find.text('Baseline'), findsNothing);
    });

    testWidgets('dark→light toggle also preserves overlay', (
      WidgetTester tester,
    ) async {
      final themeMode = ValueNotifier(ThemeMode.dark);
      addTearDown(themeMode.dispose);

      await tester.pumpWidget(
        _themeControlledCard(
          themeMode: themeMode,
          map: {
            'type': 'AdaptiveCard',
            'version': '1.5',
            'body': [
              {'type': 'TextBlock', 'id': 'msg', 'text': 'Original'},
            ],
          },
        ),
      );
      await tester.pumpAndSettle();

      tester
          .state<RawAdaptiveCardState>(find.byType(RawAdaptiveCard))
          .setText('msg', 'Dark overlay');
      await tester.pump();
      expect(find.text('Dark overlay'), findsOneWidget);

      themeMode.value = ThemeMode.light;
      await tester.pumpAndSettle();

      expect(find.text('Dark overlay'), findsOneWidget);
    });

    testWidgets('typed input text is preserved after brightness toggle', (
      WidgetTester tester,
    ) async {
      final themeMode = ValueNotifier(ThemeMode.light);
      addTearDown(themeMode.dispose);

      await tester.pumpWidget(
        _themeControlledCard(
          themeMode: themeMode,
          map: {
            'type': 'AdaptiveCard',
            'version': '1.5',
            'body': [
              {
                'type': 'Input.Text',
                'id': 'name',
                'label': 'Name',
                'placeholder': 'Enter name',
              },
            ],
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'typed value');
      await tester.pump();
      expect(find.text('typed value'), findsOneWidget);

      themeMode.value = ThemeMode.dark;
      await tester.pumpAndSettle();

      expect(find.text('typed value'), findsOneWidget);
    });

    testWidgets('multiple brightness toggles preserve overlay', (
      WidgetTester tester,
    ) async {
      final themeMode = ValueNotifier(ThemeMode.light);
      addTearDown(themeMode.dispose);

      await tester.pumpWidget(
        _themeControlledCard(
          themeMode: themeMode,
          map: {
            'type': 'AdaptiveCard',
            'version': '1.5',
            'body': [
              {'type': 'TextBlock', 'id': 'label', 'text': 'Base'},
            ],
          },
        ),
      );
      await tester.pumpAndSettle();

      tester
          .state<RawAdaptiveCardState>(find.byType(RawAdaptiveCard))
          .setText('label', 'Persistent');
      await tester.pump();
      expect(find.text('Persistent'), findsOneWidget);

      for (final mode in [
        ThemeMode.dark,
        ThemeMode.light,
        ThemeMode.dark,
        ThemeMode.light,
      ]) {
        themeMode.value = mode;
        await tester.pumpAndSettle();
        expect(
          find.text('Persistent'),
          findsOneWidget,
          reason: 'overlay lost after switch to $mode',
        );
      }
    });
  });
}
