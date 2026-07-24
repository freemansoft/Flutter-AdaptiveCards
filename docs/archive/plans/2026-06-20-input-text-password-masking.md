# Input.Text Password Masking Implementation Plan

> **Status: ✅ Complete** — shipped in PR #40. Archived 2026-07-02.
> Checkbox state below is historical and was not ticked at merge time.

---

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

> **COMMIT GATE (project + user rule):** This work is on branch `feat/input-text-password-masking`.
> The user reviews **every** diff before any commit. Do **not** run a `git commit` step until the user
> has reviewed and approved that task's changes. Never push without explicit approval.

**Goal:** Implement Adaptive Cards password masking (`Input.Text` `"style": "password"` obscures typed characters) plus an optional show/hide eye-icon toggle controlled by HostConfig with a per-element runtime overlay override, demonstrated by a widgetbook knob.

**Architecture:** The widget reads the resolved `style` and sets `obscureText`. The eye-icon's availability resolves with precedence **Overlay > HostConfig > FallbackConfig**: a `revealPasswordEnabled` boolean on a nested, non-standard `TextInputConfig` (`inputs.text.revealPasswordEnabled`, default from the mirrored `FallbackConfigs.inputsConfig`) is overridable per element via a new `ElementOverlay.revealPasswordEnabled` patch, exposed through the existing notifier/`resolvedElementProvider`/`RawAdaptiveCardState` facade. A widgetbook overlay-demo page drives that overlay from a boolean knob.

**Tech Stack:** Flutter/Dart, Riverpod (card-scoped providers), hand-written HostConfig `fromJson` (no codegen), `flutter_test`, widgetbook (`build_runner` for `@widgetbook.UseCase`). All commands via `fvm`.

---

## Spec reference

Design: `docs/superpowers/specs/2026-06-20-input-text-password-masking-design.md`.

## File structure (what changes and why)

| File | Responsibility | Change |
| --- | --- | --- |
| `packages/flutter_adaptive_cards_fs/lib/src/cards/inputs/text.dart` | Renders `Input.Text` | Add password obscuring, keyboard type, eye-icon toggle + precedence resolution |
| `packages/flutter_adaptive_cards_fs/lib/src/hostconfig/fallback_configs.dart` | Built-in HostConfig defaults | Add `inputsConfig` (`InputsConfig` mirror) |
| `packages/flutter_adaptive_cards_fs/lib/src/hostconfig/text_input_config.dart` (new) | `inputs.text` sub-config | `TextInputConfig.revealPasswordEnabled` (non-standard) |
| `packages/flutter_adaptive_cards_fs/lib/src/hostconfig/inputs_config.dart` | `inputs` HostConfig section | Add nested `text` (`TextInputConfig`) |
| `packages/flutter_adaptive_cards_fs/lib/src/riverpod/adaptive_card_document.dart` | `ElementOverlay` model | Add `revealPasswordEnabled` overlay field |
| `packages/flutter_adaptive_cards_fs/lib/src/riverpod/adaptive_card_document_notifier.dart` | Overlay mutations + reset | Add set/clear methods; preserve field on reset |
| `packages/flutter_adaptive_cards_fs/lib/src/riverpod/providers.dart` | `resolvedElementProvider` merge | Merge `revealPasswordEnabled` overlay |
| `packages/flutter_adaptive_cards_fs/lib/src/resolved_input_state.dart` | Resolved input view | Add `revealPasswordEnabledOverride` getter |
| `packages/flutter_adaptive_cards_fs/lib/src/flutter_raw_adaptive_card.dart` | Public host facade | Add set/clear facade methods |
| `widgetbook/lib/samples/inputs/input_text/password_overlay_demo.json` | Demo card JSON | New asset |
| `widgetbook/lib/input_text_password_overlay_page.dart` | Demo page with knob | New page |
| `widgetbook/lib/adaptive_cards_use_cases.dart` | Use-case registry | Register the page |
| docs + CHANGELOG | Architecture-doc-sync gate | Update |

---

## Task 1: Password masking (obscureText + keyboard type)

**Files:**
- Modify: `packages/flutter_adaptive_cards_fs/lib/src/cards/inputs/text.dart`
- Test: `packages/flutter_adaptive_cards_fs/test/inputs/text_password_test.dart` (new)

- [ ] **Step 1: Write the failing test**

Create `packages/flutter_adaptive_cards_fs/test/inputs/text_password_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../utils/test_utils.dart';

Map<String, dynamic> _cardWith(Map<String, dynamic> input) => {
      'type': 'AdaptiveCard',
      'body': [input],
    };

void main() {
  testWidgets('password style obscures the text field', (tester) async {
    final widget = getTestWidgetFromMap(
      map: _cardWith({
        'type': 'Input.Text',
        'id': 'pwd',
        'label': 'Password',
        'style': 'password',
      }),
      title: 'Password Input Test',
    );

    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    final editable = tester.widget<EditableText>(find.byType(EditableText));
    expect(editable.obscureText, isTrue);
  });

  testWidgets('non-password style does not obscure', (tester) async {
    final widget = getTestWidgetFromMap(
      map: _cardWith({
        'type': 'Input.Text',
        'id': 'plain',
        'label': 'Name',
      }),
      title: 'Plain Input Test',
    );

    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    final editable = tester.widget<EditableText>(find.byType(EditableText));
    expect(editable.obscureText, isFalse);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd packages/flutter_adaptive_cards_fs && fvm flutter test test/inputs/text_password_test.dart`
Expected: FAIL on the password test (`obscureText` is `false` because password style is unimplemented).

- [ ] **Step 3: Implement password obscuring in the widget**

In `packages/flutter_adaptive_cards_fs/lib/src/cards/inputs/text.dart`:

3a. Add the obscure flag field next to the other state fields (after `bool _initialValueSynced = false;` on line 44):

```dart
  /// Whether password characters are currently hidden (`style: password`).
  bool _obscure = true;
```

3b. Add a `password` case to `resolveTextInputType()` (inside the `switch`, before `default`):

```dart
      case 'password':
        return TextInputType.visiblePassword;
```

3c. Add a resolved `style` getter to `packages/flutter_adaptive_cards_fs/lib/src/resolved_input_state.dart` (so the flag derives from merged baseline+overlay state, not the raw `adaptiveMap`):

```dart
  /// Resolved `"style"` (overlay or baseline), lowercased; `null` when absent.
  String? get style => (map['style'] as String?)?.toLowerCase();
```

Then in `build()`, compute the password flag from the resolved input, immediately after `final input = watchResolvedInput();`:

```dart
    final isPassword = input.style == 'password';
```

3d. On the `TextFormField`, change `maxLines` and add the obscure/keyboard-safety properties. Replace:

```dart
                keyboardType: inputStyle,
                maxLines: isMultiline ? null : 1,
```

with:

```dart
                keyboardType: inputStyle,
                obscureText: isPassword && _obscure,
                enableSuggestions: !isPassword,
                autocorrect: !isPassword,
                maxLines: (isMultiline && !isPassword) ? null : 1,
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd packages/flutter_adaptive_cards_fs && fvm flutter test test/inputs/text_password_test.dart`
Expected: PASS (both tests).

- [ ] **Step 5: Commit** (after user review of the diff)

```bash
git add packages/flutter_adaptive_cards_fs/lib/src/cards/inputs/text.dart \
        packages/flutter_adaptive_cards_fs/test/inputs/text_password_test.dart
git commit -m "feat(inputs): obscure Input.Text password style"
```

---

## Task 2: HostConfig `inputs.text.revealPasswordEnabled` (nested, non-standard) + mirrored FallbackConfig

> **As-built note:** the reveal flag is a **non-standard** custom HostConfig extension nested under a
> new `TextInputConfig` (`inputs.text.revealPasswordEnabled`), and the FallbackConfig mirrors the
> section as a full `InputsConfig` (`FallbackConfigs.inputsConfig`). Flag it **Non-standard** in the
> Dart `///` comments and in `docs/hostconfig.md`.

**Files:**
- Create: `packages/flutter_adaptive_cards_fs/lib/src/hostconfig/text_input_config.dart`
- Modify: `packages/flutter_adaptive_cards_fs/lib/src/hostconfig/inputs_config.dart`
- Modify: `packages/flutter_adaptive_cards_fs/lib/src/hostconfig/fallback_configs.dart`
- Test: `packages/flutter_adaptive_cards_fs/test/hostconfig/inputs_config_test.dart`,
  `packages/flutter_adaptive_cards_fs/test/hostconfig/text_input_config_test.dart` (new)

- [ ] **Step 1: Write the failing tests**

In `test/hostconfig/inputs_config_test.dart`, inside `group('InputsConfig', ...)`:

```dart
    test('text.revealPasswordEnabled defaults to true when absent', () {
      final config = InputsConfig.fromJson({});
      expect(config.text.revealPasswordEnabled, isTrue);
    });

    test('text.revealPasswordEnabled parses explicit false', () {
      final config = InputsConfig.fromJson({
        'text': {'revealPasswordEnabled': false},
      });
      expect(config.text.revealPasswordEnabled, isFalse);
    });
```

New `test/hostconfig/text_input_config_test.dart`:

```dart
import 'package:flutter_adaptive_cards_fs/src/hostconfig/text_input_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TextInputConfig', () {
    test('revealPasswordEnabled defaults to true when absent', () {
      final config = TextInputConfig.fromJson({});
      expect(config.revealPasswordEnabled, isTrue);
    });

    test('revealPasswordEnabled parses explicit false', () {
      final config = TextInputConfig.fromJson({'revealPasswordEnabled': false});
      expect(config.revealPasswordEnabled, isFalse);
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd packages/flutter_adaptive_cards_fs && fvm flutter test test/hostconfig`
Expected: FAIL to compile (`TextInputConfig` / `config.text` undefined).

- [ ] **Step 3: Create `TextInputConfig`**

`packages/flutter_adaptive_cards_fs/lib/src/hostconfig/text_input_config.dart`:

```dart
import 'package:flutter_adaptive_cards_fs/src/hostconfig/fallback_configs.dart';

/// HostConfig `inputs.text` section — settings specific to `Input.Text`.
///
/// **Non-standard:** custom extension to HostConfig, not part of the official
/// Adaptive Cards HostConfig schema.
class TextInputConfig {
  /// Creates `Input.Text` settings from explicit values.
  TextInputConfig({required this.revealPasswordEnabled});

  /// Parses `inputs.text` from HostConfig JSON.
  factory TextInputConfig.fromJson(Map<String, dynamic> json) {
    return TextInputConfig(
      revealPasswordEnabled: json['revealPasswordEnabled'] as bool? ??
          FallbackConfigs.inputsConfig.text.revealPasswordEnabled,
    );
  }

  /// Whether `Input.Text` password fields show a show/hide eye-icon toggle.
  ///
  /// **Non-standard:** custom extension. Host default; a per-element overlay can
  /// override this at runtime.
  final bool revealPasswordEnabled;
}
```

- [ ] **Step 4: Add nested `text` to `InputsConfig`**

In `inputs_config.dart`, import `text_input_config.dart`, add `required this.text` to the constructor,
parse `text: TextInputConfig.fromJson(json['text'] ?? {})`, and add a `final TextInputConfig text;`
field with a **Non-standard** `///` note. (`fallback_configs.dart` import is no longer needed here.)

- [ ] **Step 5: Mirror the section in FallbackConfigs**

In `fallback_configs.dart`, add (imports: `inputs_config.dart`, `label_config.dart`,
`error_message_config.dart`, `text_input_config.dart`):

```dart
  /// Default `inputs` section values.
  ///
  /// **Non-standard:** the `text.revealPasswordEnabled` flag is a custom
  /// extension, not part of the official Adaptive Cards HostConfig schema.
  static final InputsConfig inputsConfig = InputsConfig(
    label: LabelConfig.fromJson(const <String, dynamic>{}),
    errorMessage: ErrorMessageConfig.fromJson(const <String, dynamic>{}),
    text: TextInputConfig(revealPasswordEnabled: true),
  );
```

(Build `text` with the direct `TextInputConfig(...)` constructor — not `fromJson` — to avoid
lazy-init reentrancy, since `TextInputConfig.fromJson` reads `FallbackConfigs.inputsConfig`.)

- [ ] **Step 6: Run tests to verify they pass**

Run: `cd packages/flutter_adaptive_cards_fs && fvm flutter test test/hostconfig && fvm flutter analyze`
Expected: PASS; analyze clean (confirms no call site referenced a removed flat property).

- [ ] **Step 7: Commit** (after user review of the diff)

```bash
git add packages/flutter_adaptive_cards_fs/lib/src/hostconfig/text_input_config.dart \
        packages/flutter_adaptive_cards_fs/lib/src/hostconfig/inputs_config.dart \
        packages/flutter_adaptive_cards_fs/lib/src/hostconfig/fallback_configs.dart \
        packages/flutter_adaptive_cards_fs/test/hostconfig/inputs_config_test.dart \
        packages/flutter_adaptive_cards_fs/test/hostconfig/text_input_config_test.dart
git commit -m "feat(hostconfig): add non-standard inputs.text.revealPasswordEnabled"
```

---

## Task 3: Per-element `revealPasswordEnabled` overlay (model + notifier + resolve + facade)

**Files:**
- Modify: `packages/flutter_adaptive_cards_fs/lib/src/riverpod/adaptive_card_document.dart`
- Modify: `packages/flutter_adaptive_cards_fs/lib/src/riverpod/adaptive_card_document_notifier.dart`
- Modify: `packages/flutter_adaptive_cards_fs/lib/src/riverpod/providers.dart`
- Modify: `packages/flutter_adaptive_cards_fs/lib/src/resolved_input_state.dart`
- Modify: `packages/flutter_adaptive_cards_fs/lib/src/flutter_raw_adaptive_card.dart`
- Test: `packages/flutter_adaptive_cards_fs/test/riverpod/adaptive_card_document_notifier_test.dart`

- [ ] **Step 1: Write the failing tests**

This file already provides a top-level `_createContainer(Map baseline)` helper (around line 103) that
overrides `baselineMapProvider`. Add a new top-level password baseline (next to `_baselineFixture()`,
around line 35):

```dart
Map<String, dynamic> _passwordBaseline() {
  return {
    'type': 'AdaptiveCard',
    'version': '1.5',
    'body': [
      {
        'type': 'Input.Text',
        'id': 'pwd',
        'style': 'password',
      },
    ],
  };
}
```

Then add a new sibling group inside `main()` (after the existing `group('AdaptiveCardDocumentNotifier', ...)`):

```dart
  group('revealPasswordEnabled overlay', () {
    late ProviderContainer container;

    setUp(() {
      container = _createContainer(_passwordBaseline());
    });

    tearDown(() {
      container.dispose();
    });

    test('setRevealPasswordEnabled merges into resolvedElementProvider', () {
      container
          .read(adaptiveCardDocumentProvider.notifier)
          .setRevealPasswordEnabled('pwd', enabled: false);

      final resolved = container.read(resolvedElementProvider('pwd'));
      expect(resolved?['revealPasswordEnabled'], isFalse);
    });

    test('clearRevealPasswordEnabled removes the override', () {
      final notifier = container.read(adaptiveCardDocumentProvider.notifier)
        ..setRevealPasswordEnabled('pwd', enabled: false)
        ..clearRevealPasswordEnabled('pwd');

      expect(
        notifier.state.overlaysById['pwd']?.revealPasswordEnabled,
        isNull,
      );
      final resolved = container.read(resolvedElementProvider('pwd'));
      expect(resolved?.containsKey('revealPasswordEnabled'), isFalse);
    });

    test('resetInput preserves revealPasswordEnabled override', () {
      final notifier = container.read(adaptiveCardDocumentProvider.notifier)
        ..setRevealPasswordEnabled('pwd', enabled: false)
        ..resetInput('pwd');

      expect(
        notifier.state.overlaysById['pwd']?.revealPasswordEnabled,
        isFalse,
      );
    });
  });
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd packages/flutter_adaptive_cards_fs && fvm flutter test test/riverpod/adaptive_card_document_notifier_test.dart`
Expected: FAIL to compile ("method 'setRevealPasswordEnabled' isn't defined").

- [ ] **Step 3a: Add the overlay field to `ElementOverlay`**

In `packages/flutter_adaptive_cards_fs/lib/src/riverpod/adaptive_card_document.dart`:

Add to the `ElementOverlay` constructor (after `this.extensionPayloads,`):

```dart
    this.revealPasswordEnabled,
```

Add the field (after the `extensionPayloads` field doc/declaration, before `copyWith`):

```dart
  /// Overrides the host `inputs.text.revealPasswordEnabled` default for one
  /// `Input.Text` password field when non-null.
  final bool? revealPasswordEnabled;
```

Add to `copyWith` parameters (after `Map<String, Map<String, dynamic>>? extensionPayloads,`):

```dart
    bool? revealPasswordEnabled,
```

Add the clear flag (after `bool clearExtensionPayloads = false,`):

```dart
    bool clearRevealPasswordEnabled = false,
```

Add to the returned `ElementOverlay(...)` (after the `extensionPayloads:` line):

```dart
      revealPasswordEnabled: clearRevealPasswordEnabled
          ? null
          : (revealPasswordEnabled ?? this.revealPasswordEnabled),
```

- [ ] **Step 3b: Add notifier set/clear methods**

In `packages/flutter_adaptive_cards_fs/lib/src/riverpod/adaptive_card_document_notifier.dart`,
add after `clearIsRequired` (after line ~309):

```dart
  /// Overrides the host `inputs.text.revealPasswordEnabled` default for input [id].
  void setRevealPasswordEnabled(String id, {required bool enabled}) {
    _updateOverlay(
      id,
      (current) => (current ?? const ElementOverlay()).copyWith(
        revealPasswordEnabled: enabled,
      ),
    );
  }

  /// Clears the `revealPasswordEnabled` override for [id].
  void clearRevealPasswordEnabled(String id) {
    _updateOverlay(
      id,
      (current) => (current ?? const ElementOverlay()).copyWith(
        clearRevealPasswordEnabled: true,
      ),
    );
  }
```

- [ ] **Step 3c: Preserve the field on factory reset**

In the same notifier file, update `_factoryResetInputOverlay` so the override survives `Action.ResetInputs`.
Replace the method body's null-check and constructor:

```dart
  ElementOverlay? _factoryResetInputOverlay(ElementOverlay current) {
    if (current.isVisible == null &&
        current.queryCount == null &&
        current.querySkip == null &&
        current.querySearchText == null &&
        current.revealPasswordEnabled == null) {
      return null;
    }
    return ElementOverlay(
      isVisible: current.isVisible,
      queryCount: current.queryCount,
      querySkip: current.querySkip,
      querySearchText: current.querySearchText,
      revealPasswordEnabled: current.revealPasswordEnabled,
    );
  }
```

- [ ] **Step 3d: Merge in `resolvedElementProvider`**

In `packages/flutter_adaptive_cards_fs/lib/src/riverpod/providers.dart`, in the
`resolvedElementProvider` family, add after the `isRequired` merge block (after line ~118):

```dart
    if (overlay?.revealPasswordEnabled != null) {
      merged['revealPasswordEnabled'] = overlay!.revealPasswordEnabled;
    }
```

- [ ] **Step 3e: Add the resolved getter**

In `packages/flutter_adaptive_cards_fs/lib/src/resolved_input_state.dart`, add after the
`isInvalid` getter (after line 37):

```dart
  /// Per-element override of the password reveal toggle, or `null` when unset.
  ///
  /// `null` means "no overlay override" — the widget falls back to HostConfig.
  bool? get revealPasswordEnabledOverride =>
      map['revealPasswordEnabled'] as bool?;
```

- [ ] **Step 3f: Add the public facade methods**

In `packages/flutter_adaptive_cards_fs/lib/src/flutter_raw_adaptive_card.dart`, add after
`clearText` (after line ~269):

```dart
  /// Overrides the host `inputs.text.revealPasswordEnabled` default for input [id].
  void setRevealPasswordEnabled(String id, {required bool enabled}) {
    final container = documentContainer;
    if (container == null) return;
    container
        .read(adaptiveCardDocumentProvider.notifier)
        .setRevealPasswordEnabled(id, enabled: enabled);
  }

  /// Clears the password reveal toggle override for [id].
  void clearRevealPasswordEnabled(String id) {
    final container = documentContainer;
    if (container == null) return;
    container
        .read(adaptiveCardDocumentProvider.notifier)
        .clearRevealPasswordEnabled(id);
  }
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd packages/flutter_adaptive_cards_fs && fvm flutter test test/riverpod/adaptive_card_document_notifier_test.dart`
Expected: PASS (the new group plus all existing tests).

- [ ] **Step 5: Commit** (after user review of the diff)

```bash
git add packages/flutter_adaptive_cards_fs/lib/src/riverpod/adaptive_card_document.dart \
        packages/flutter_adaptive_cards_fs/lib/src/riverpod/adaptive_card_document_notifier.dart \
        packages/flutter_adaptive_cards_fs/lib/src/riverpod/providers.dart \
        packages/flutter_adaptive_cards_fs/lib/src/resolved_input_state.dart \
        packages/flutter_adaptive_cards_fs/lib/src/flutter_raw_adaptive_card.dart \
        packages/flutter_adaptive_cards_fs/test/riverpod/adaptive_card_document_notifier_test.dart
git commit -m "feat(overlay): add revealPasswordEnabled per-element override"
```

---

## Task 4: Eye-icon reveal toggle wired to precedence

**Files:**
- Modify: `packages/flutter_adaptive_cards_fs/lib/src/cards/inputs/text.dart`
- Test: `packages/flutter_adaptive_cards_fs/test/inputs/text_password_test.dart`

- [ ] **Step 1: Write the failing tests**

Append to `packages/flutter_adaptive_cards_fs/test/inputs/text_password_test.dart` (add the import
for the package public API at the top: `import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';`),
then add inside `main()`:

```dart
  testWidgets('eye-icon shows by default and toggles obscure state',
      (tester) async {
    final widget = getTestWidgetFromMap(
      map: _cardWith({
        'type': 'Input.Text',
        'id': 'pwd',
        'label': 'Password',
        'style': 'password',
      }),
      title: 'Password Reveal Test',
    );

    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    // Obscured initially: shows the "reveal" icon.
    expect(find.byIcon(Icons.visibility), findsOneWidget);
    expect(tester.widget<EditableText>(find.byType(EditableText)).obscureText,
        isTrue);

    await tester.tap(find.byIcon(Icons.visibility));
    await tester.pumpAndSettle();

    // Revealed: shows the "hide" icon and text is no longer obscured.
    expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    expect(tester.widget<EditableText>(find.byType(EditableText)).obscureText,
        isFalse);
  });

  testWidgets('eye-icon hidden when HostConfig disables it', (tester) async {
    final hostConfigs = HostConfigs(
      light: HostConfig.fromJson(const {
        'inputs': {
          'text': {'revealPasswordEnabled': false},
        },
      }),
      dark: HostConfig.fromJson(const {
        'inputs': {
          'text': {'revealPasswordEnabled': false},
        },
      }),
    );

    final widget = getTestWidgetFromMap(
      map: _cardWith({
        'type': 'Input.Text',
        'id': 'pwd',
        'label': 'Password',
        'style': 'password',
      }),
      title: 'Password No Reveal Test',
      hostConfigs: hostConfigs,
    );

    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.visibility), findsNothing);
    expect(find.byIcon(Icons.visibility_off), findsNothing);
    expect(tester.widget<EditableText>(find.byType(EditableText)).obscureText,
        isTrue);
  });
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd packages/flutter_adaptive_cards_fs && fvm flutter test test/inputs/text_password_test.dart`
Expected: FAIL — no eye-icon is rendered yet (`find.byIcon(Icons.visibility)` finds nothing).

- [ ] **Step 3: Implement the eye-icon + precedence resolution**

In `packages/flutter_adaptive_cards_fs/lib/src/cards/inputs/text.dart`:

3a. Add the fallback-config import at the top (with the other `src/` imports):

```dart
import 'package:flutter_adaptive_cards_fs/src/hostconfig/fallback_configs.dart';
```

3b. In `build()`, immediately after `final isPassword = input.style == 'password';` (added in Task 1),
compute the effective reveal-enabled value (Overlay > HostConfig > FallbackConfig). The HostConfig
property lives on the nested `TextInputConfig` (`inputs.text.revealPasswordEnabled`), and the widget
falls back at the `InputsConfig` level (matching the resolver fallback pattern):

```dart
    final inputsConfig =
        styleResolver.getInputsConfig() ?? FallbackConfigs.inputsConfig;
    final revealEnabled = input.revealPasswordEnabledOverride ??
        inputsConfig.text.revealPasswordEnabled;
```

3c. Add a `suffixIcon` to the `InputDecoration` (place it after the `hintStyle:` line, before
`errorStyle:`), and constrain it so it fits the field:

```dart
                  suffixIcon: (isPassword && revealEnabled)
                      ? IconButton(
                          padding: EdgeInsets.zero,
                          iconSize: 20,
                          constraints: const BoxConstraints(
                            maxHeight: 36,
                            maxWidth: 36,
                          ),
                          icon: Icon(
                            _obscure ? Icons.visibility : Icons.visibility_off,
                          ),
                          // Library has no l10n/arb setup (intl is date-only),
                          // so these accessibility labels are plain strings,
                          // consistent with the rest of the package.
                          tooltip: _obscure ? 'Show password' : 'Hide password',
                          onPressed: () =>
                              setState(() => _obscure = !_obscure),
                        )
                      : null,
                  suffixIconConstraints: const BoxConstraints(
                    maxHeight: 36,
                    maxWidth: 36,
                  ),
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd packages/flutter_adaptive_cards_fs && fvm flutter test test/inputs/text_password_test.dart`
Expected: PASS (all four tests).

- [ ] **Step 5: Run the input + hostconfig + riverpod suites for regressions**

Run: `cd packages/flutter_adaptive_cards_fs && fvm flutter test test/inputs test/hostconfig test/riverpod`
Expected: PASS (watch for layout-overflow assertions from the suffix icon; if any, the
`SizedBox(height: 40)` wrapping the `TextFormField` can be raised to `48` — re-run after).

- [ ] **Step 6: Commit** (after user review of the diff)

```bash
git add packages/flutter_adaptive_cards_fs/lib/src/cards/inputs/text.dart \
        packages/flutter_adaptive_cards_fs/test/inputs/text_password_test.dart
git commit -m "feat(inputs): add password reveal eye-icon toggle"
```

---

## Task 5: Widgetbook demo with reveal-toggle knob

**Files:**
- Create: `widgetbook/lib/samples/inputs/input_text/password_overlay_demo.json`
- Create: `widgetbook/lib/input_text_password_overlay_page.dart`
- Modify: `widgetbook/lib/adaptive_cards_use_cases.dart`
- Generated (do not hand-edit): `widgetbook/lib/main.directories.g.dart`

- [ ] **Step 1: Create the demo card JSON**

Create `widgetbook/lib/samples/inputs/input_text/password_overlay_demo.json`:

```json
{
  "$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
  "type": "AdaptiveCard",
  "version": "1.5",
  "body": [
    {
      "type": "TextBlock",
      "text": "Use the 'Enable password reveal toggle' knob to show/hide the eye-icon.",
      "wrap": true
    },
    {
      "type": "Input.Text",
      "id": "passwordField",
      "label": "Password",
      "placeholder": "Enter your password",
      "style": "password",
      "maxLength": 64
    }
  ],
  "actions": [
    {
      "type": "Action.Submit",
      "title": "Sign in"
    }
  ]
}
```

- [ ] **Step 2: Create the overlay demo page**

Create `widgetbook/lib/input_text_password_overlay_page.dart`:

```dart
// Host-only demo: calls [RawAdaptiveCardState.setRevealPasswordEnabled].

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_workspace/overlay_demo_scaffold.dart';
import 'package:widgetbook_workspace/widgetbook_card_registry.dart';

const _passwordId = 'passwordField';

final inputTextPasswordOverlayPageKey =
    GlobalKey<State<InputTextPasswordOverlayPage>>();

class InputTextPasswordOverlayPage extends StatefulWidget {
  const InputTextPasswordOverlayPage({super.key});

  @override
  State<InputTextPasswordOverlayPage> createState() =>
      _InputTextPasswordOverlayPageState();
}

class _InputTextPasswordOverlayPageState
    extends State<InputTextPasswordOverlayPage>
    with OverlayDemoPageState<InputTextPasswordOverlayPage> {
  static const _assetPath =
      'lib/samples/inputs/input_text/password_overlay_demo.json';

  bool? _lastApplied;
  bool? _pending;
  bool _knobsInitialized = false;
  bool? _lastSeenKnob;

  @override
  void initState() {
    super.initState();
    unawaited(loadOverlayCardAsset(_assetPath));
  }

  void _queueOverlay(bool revealEnabled) {
    _pending = revealEnabled;
    if (_lastApplied == revealEnabled) return;
    scheduleOverlayApply(_flushPendingOverlay);
  }

  void _flushPendingOverlay() {
    final revealEnabled = _pending;
    if (revealEnabled == null) return;

    runWhenCardReady(
      (cardState) {
        if (_lastApplied == revealEnabled) return;
        cardState.setRevealPasswordEnabled(
          _passwordId,
          enabled: revealEnabled,
        );
        _lastApplied = revealEnabled;
      },
      reschedule: () => scheduleOverlayApply(_flushPendingOverlay),
    );
  }

  void _syncKnob(bool revealEnabled) {
    if (!_knobsInitialized) {
      _knobsInitialized = true;
      _lastSeenKnob = revealEnabled;
      return;
    }
    if (revealEnabled == _lastSeenKnob) return;
    _lastSeenKnob = revealEnabled;
    _queueOverlay(revealEnabled);
  }

  @override
  Widget build(BuildContext context) {
    final revealEnabled = context.knobs.boolean(
      label: 'Enable password reveal toggle',
      initialValue: true,
    );
    _syncKnob(revealEnabled);
    return buildOverlayCard(registry: widgetbookCardTypeRegistry);
  }
}
```

- [ ] **Step 3: Register the use-case**

In `widgetbook/lib/adaptive_cards_use_cases.dart`:

3a. Add the import near the other page imports (alphabetical with the existing
`rating_input_overlay_page.dart` import on line 9):

```dart
import 'package:widgetbook_workspace/input_text_password_overlay_page.dart';
```

3b. Add a use-case builder (place it among the other `widget_types.InputText` use-cases):

```dart
@widgetbook.UseCase(
  name: 'Password reveal overlay (knob)',
  type: widget_types.InputText,
  path: '[Components]',
)
Widget buildInputTextPasswordOverlay(BuildContext context) {
  return InputTextPasswordOverlayPage(key: inputTextPasswordOverlayPageKey);
}
```

- [ ] **Step 4: Regenerate the widgetbook directories**

Run: `cd widgetbook && fvm dart run build_runner build -d`
Expected: completes; `widgetbook/lib/main.directories.g.dart` now references `buildInputTextPasswordOverlay`.

- [ ] **Step 5: Analyze the widgetbook package**

Run: `cd widgetbook && fvm flutter analyze`
Expected: No issues.

- [ ] **Step 6: Manual smoke check**

Run the widgetbook app (`cd widgetbook && fvm flutter run -d <device>` or Chrome), open
`[Components] → Input.Text → Password reveal overlay (knob)`. Confirm: the field is obscured, the
eye-icon toggles visibility, and the "Enable password reveal toggle" knob shows/hides the eye-icon.

- [ ] **Step 7: Commit** (after user review of the diff)

```bash
git add widgetbook/lib/samples/inputs/input_text/password_overlay_demo.json \
        widgetbook/lib/input_text_password_overlay_page.dart \
        widgetbook/lib/adaptive_cards_use_cases.dart \
        widgetbook/lib/main.directories.g.dart
git commit -m "docs(widgetbook): add password reveal toggle demo"
```

---

## Task 6: Docs + changelog (architecture-doc-sync gate)

**Files:**
- Modify: `packages/flutter_adaptive_cards_fs/CHANGELOG.md`
- Modify: `docs/form-inputs.md`
- Modify: `docs/hostconfig.md`
- Modify: `docs/overlay-properties-by-type.md`
- Modify: `docs/reactive-riverpod.md`
- Modify: `docs/Implementation-Status.md`

- [ ] **Step 1: CHANGELOG** — add a bullet under `## [Unreleased]` in
  `packages/flutter_adaptive_cards_fs/CHANGELOG.md`:

```markdown
- Add `Input.Text` password masking (`style: "password"`) with an optional reveal (eye-icon) toggle.
  The toggle is controlled by HostConfig `inputs.text.revealPasswordEnabled` (default `true`) and can be
  overridden per element at runtime via `RawAdaptiveCardState.setRevealPasswordEnabled`.
```

- [ ] **Step 2: `docs/form-inputs.md`** — add a section after the existing
  "Input.Text — phone style and character filtering" section:

```markdown
### Input.Text — password masking and reveal toggle

`"style": "password"` obscures typed characters (client-side display only; the value is still
submitted as clear text, matching the Adaptive Cards / Teams spec). Password fields are forced to a
single line.

An optional show/hide **eye-icon** lets users reveal the text. Its availability resolves with
precedence **Overlay > HostConfig > FallbackConfig**:

1. Per-element overlay `revealPasswordEnabled` (`RawAdaptiveCardState.setRevealPasswordEnabled`).
2. HostConfig `inputs.text.revealPasswordEnabled` (on `TextInputConfig`, **non-standard**).
3. Built-in default `FallbackConfigs.inputsConfig.text.revealPasswordEnabled` (`true`).

The per-element override is **preserved** across `Action.ResetInputs` (it is presentation config,
not user-entered input).
```

- [ ] **Step 3: `docs/hostconfig.md`** — (DONE during Task 3 follow-up) document the new property,
  marked **Non-standard**, plus a convention note that custom HostConfig additions are flagged as
  non-standard in both Dart `///` comments and this doc. The property's Dart `///` comments
  (`inputs_config.dart` field + `fallback_configs.dart` const) are likewise marked **Non-standard**.

- [ ] **Step 4: `docs/overlay-properties-by-type.md`** — add `revealPasswordEnabled` to the
  `Input.Text` row/section (patch key `revealPasswordEnabled` → resolved key `revealPasswordEnabled`),
  noting it is preserved on reset.

- [ ] **Step 5: `docs/reactive-riverpod.md`** — add `revealPasswordEnabled` to the `ElementOverlay`
  field list, and add it to the "preserved on reset" set alongside `isVisible` and the typeahead
  session fields.

- [ ] **Step 6: `docs/Implementation-Status.md`** — update the `Input.Text` notes to record that the
  Password style and reveal toggle are now supported.

- [ ] **Step 7: Commit** (after user review of the diff)

```bash
git add packages/flutter_adaptive_cards_fs/CHANGELOG.md docs/
git commit -m "docs: document Input.Text password masking + reveal toggle"
```

---

## Final Task: Full verification

- [ ] **Step 1: Analyze the whole repo**

Run (repo root): `fvm flutter analyze`
Expected: No issues.

- [ ] **Step 2: Run the full main-library suite (plan-completion gate)**

Run: `cd packages/flutter_adaptive_cards_fs && fvm flutter test --exclude-tags=golden`
Expected: All tests pass. Record pass/fail counts and exit code.

- [ ] **Step 3: Widgetbook codegen + analyze**

Run: `cd widgetbook && fvm dart run build_runner build -d && fvm flutter analyze`
Expected: Generates cleanly; no analyzer issues.

- [ ] **Step 4: Invoke `verification-before-completion`**

Paste the analyze + test output (exit codes, pass/fail counts) before claiming completion. Do not
claim done until the full suite passes.

- [ ] **Step 5: Commit the spec doc + design** (after user review)

If not already committed, include the spec at
`docs/superpowers/specs/2026-06-20-input-text-password-masking-design.md` and this plan in the final
commit set. Then offer `finishing-a-development-branch`.

---

## Notes / risks

- **Suffix-icon layout:** the field is wrapped in `SizedBox(height: 40)`; the icon button is
  constrained to 36×36 with `iconSize: 20`. If a render-overflow assertion appears in tests, raise
  the `SizedBox` height to `48` (Task 4, Step 5).
- **`obscureText` + multiline:** Flutter forbids both; Task 1 forces password fields to single line.
- **No localization for icon labels:** the library has no `AppLocalizations`/arb setup (`intl` is used
  only for date formatting), so the eye-icon tooltip strings are plain literals, consistent with the
  rest of the package. Revisit if/when the library gains an l10n layer.
- **HostConfig default of `null` inputs section:** a bare `HostConfig()` has `inputs == null`, so
  `getInputsConfig()?.revealPasswordEnabled` is `null` and the chain falls through to the
  FallbackConfig default (`true`) — eye-icon visible by default, as intended.
