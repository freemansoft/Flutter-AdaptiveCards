# Design: Input.Text Password Masking with Reveal (Eye-Icon) Toggle

- **Status:** Draft for review
- **Date:** 2026-06-20
- **Package:** `flutter_adaptive_cards_fs` (+ `widgetbook` sample)

### Resolved decisions

- **HostConfig property:** nested boolean `inputs.text.revealPasswordEnabled` on a `TextInputConfig`
  object inside `InputsConfig` (custom/non-standard extension).
- **FallbackConfig:** `FallbackConfigs.inputsConfig` mirrors the `inputs` section as a full
  `InputsConfig` (its `text.revealPasswordEnabled` defaults to `true`). The widget falls back to it at
  the `InputsConfig` level when the host provides none.
- **Reset behavior:** the per-element `revealPasswordEnabled` overlay is **preserved** on
  `Action.ResetInputs` (treated as a presentation/config override, not user-entered input).

## Context

The Adaptive Cards / Microsoft Teams spec defines "information masking" as **password masking**: an
`Input.Text` with `"style": "password"` must obscure typed characters. Masking is client-side display
only — the value is still submitted as clear text. (Source: Teams _Format Text in Cards_ → "Information
masking in Adaptive Cards": _"add the `style` property to type `Input.Text`, and set its value to
Password."_)

This library does **not** currently support the Password style. In
`packages/flutter_adaptive_cards_fs/lib/src/cards/inputs/text.dart`, `resolveTextInputType()` returns
`null` for `password` and there is no `obscureText` handling, so `"style": "password"` renders an
ordinary visible text field.

This change implements password masking **plus** a non-standard convenience extension: an optional
show/hide **eye-icon reveal toggle**.

## Goals / Non-goals

**Goals**

- `style: "password"` obscures input characters (spec compliance).
- Optional eye-icon reveal toggle to show/hide the entered text.
- Toggle availability controllable via HostConfig with a per-element runtime overlay override.
- A widgetbook demo with a knob that drives the overlay at runtime.
- Tests and documentation updates.

**Non-goals**

- Format-as-you-type masking (phone/SSN/date templates). Not part of the Adaptive Cards spec; excluded.

## Behavior & precedence

The eye-icon's availability is resolved with precedence **Overlay > HostConfig > FallbackConfig**:

| Layer          | Source                                                                                    | Default                                  |
| -------------- | ----------------------------------------------------------------------------------------- | ---------------------------------------- |
| FallbackConfig | `FallbackConfigs.inputsConfig` (`InputsConfig` mirror) → `.text.revealPasswordEnabled`     | **`true`** (built-in default)            |
| HostConfig     | `inputs.text.revealPasswordEnabled` (boolean, on `TextInputConfig`)                        | falls back to FallbackConfig when absent |
| Overlay        | per-element `revealPasswordEnabled` runtime patch                                          | overrides HostConfig for one field       |

`inputs.text` is a nested **non-standard** config object (`TextInputConfig`) on `InputsConfig`.
The widget falls back to the fallback `InputsConfig` when the host provides none, mirroring the
established resolver fallback pattern (`getX() ?? FallbackConfigs.X`). It resolves the effective value as:

```dart
final inputsConfig =
    styleResolver.getInputsConfig() ?? FallbackConfigs.inputsConfig; // HostConfig or fallback
final revealEnabled = input.revealPasswordEnabledOverride            // Overlay
    ?? inputsConfig.text.revealPasswordEnabled;                       // HostConfig / FallbackConfig
```

The field starts **obscured**. When `style == "password"` and `revealEnabled` is true, a suffix
eye-icon toggles a local obscure flag. When `revealEnabled` is false, the field is obscured with no
toggle.

## Design

### A. Widget — password style + eye-icon

File: `packages/flutter_adaptive_cards_fs/lib/src/cards/inputs/text.dart`

- Add `case 'password': return TextInputType.visiblePassword;` to `resolveTextInputType()`.
- Add local state `bool _obscure = true;`.
- Compute `final isPassword = input.style == 'password';` (from the **resolved** input state — add a
  lowercased `style` getter to `ResolvedInputState` — not the raw `adaptiveMap` getter) and
  `revealEnabled` (precedence above).
- On the `TextFormField`:
  - `obscureText: isPassword && _obscure`
  - `enableSuggestions: !isPassword`, `autocorrect: !isPassword`
  - Force single line for password: `maxLines: (isMultiline && !isPassword) ? null : 1`
    (Flutter disallows `obscureText` with multiline).
  - `suffixIcon` (`IconButton`, `Icons.visibility` / `Icons.visibility_off`) shown **only when**
    `isPassword && revealEnabled`; `onPressed` flips `_obscure` via `setState`. Add a semantic label
    ("Show password" / "Hide password") per the accessibility rule; localize via the existing
    `intl`/arb mechanism if inputs already use it. Use `isDense` / `suffixIconConstraints` and relax
    the wrapping `SizedBox(height: 40)` as needed so the icon button fits (verify visually / golden).
- `maxLength` / `LengthLimitingTextInputFormatter` and regex validation are unchanged and still apply.

### B. HostConfig property + FallbackConfig default

> **Non-standard:** `inputs.text.revealPasswordEnabled` is a custom extension, not part of the official
> Adaptive Cards HostConfig schema. Per project convention it is flagged **Non-standard** in its Dart
> `///` comments (`TextInputConfig` field, `InputsConfig.text`, and the fallback) and in `docs/hostconfig.md`.

- New `packages/flutter_adaptive_cards_fs/lib/src/hostconfig/text_input_config.dart`:
  `TextInputConfig` with `final bool revealPasswordEnabled;`, parsed in `fromJson` as
  `json['revealPasswordEnabled'] as bool? ?? FallbackConfigs.inputsConfig.text.revealPasswordEnabled`.
- `packages/flutter_adaptive_cards_fs/lib/src/hostconfig/inputs_config.dart`:
  add `final TextInputConfig text;` (+ constructor) and parse `text: TextInputConfig.fromJson(json['text'] ?? {})`.
- `packages/flutter_adaptive_cards_fs/lib/src/hostconfig/fallback_configs.dart`:
  add `static final InputsConfig inputsConfig` — a full `InputsConfig` mirror whose `text` is
  `TextInputConfig(revealPasswordEnabled: true)` (built with direct constructors to avoid lazy-init
  reentrancy).
- HostConfig parsing is hand-written `fromJson` — **no `.g.dart` / build_runner**.
- Read via the existing resolver, falling back at the `InputsConfig` level:
  `(styleResolver.getInputsConfig() ?? FallbackConfigs.inputsConfig).text.revealPasswordEnabled`
  (`getInputsConfig()` in `lib/src/reference_resolver.dart`).

### C. Per-element runtime overlay (Overlay layer)

Mirror the existing `isRequired` overlay end-to-end:

- `lib/src/riverpod/adaptive_card_document.dart` — add `final bool? revealPasswordEnabled;` to
  `ElementOverlay` (+ constructor, `copyWith` param, and `clearRevealPasswordEnabled` flag).
- `lib/src/riverpod/adaptive_card_document_notifier.dart` — add
  `setRevealPasswordEnabled(id, {required bool enabled})` and `clearRevealPasswordEnabled(id)`
  (template = `setIsRequired` / `clearIsRequired`).
- `lib/src/riverpod/providers.dart` — in `resolvedElementProvider`, merge
  `revealPasswordEnabled` into the resolved map when the overlay value is non-null.
- `lib/src/resolved_input_state.dart` — add
  `bool? get revealPasswordEnabledOverride => map['revealPasswordEnabled'] as bool?;`.
- `lib/src/flutter_raw_adaptive_card.dart` — add public facade methods
  `setRevealPasswordEnabled` / `clearRevealPasswordEnabled` delegating to the notifier
  (template = existing `setText` / `setInputError`).
- **Reset semantics**: `revealPasswordEnabled` is a presentation/config override, not user input, so
  it is **preserved** (not cleared) by `resetInput` / `resetAllInputs` (like `isVisible`).
- Optional: support it in `applyUpdates` / `AdaptiveElementUpdate` for parity with other overlays.

### D. Widgetbook demo (sample app)

- New asset `widgetbook/lib/samples/inputs/input_text/password_overlay_demo.json`: an `AdaptiveCard`
  with an `Input.Text` `"style": "password"`, a stable `"id"` (e.g. `passwordField`), label/placeholder,
  and an `Action.Submit`.
- New page `widgetbook/lib/input_text_password_overlay_page.dart` mirroring
  `rating_input_overlay_page.dart` (uses the `OverlayDemoPageState` mixin):
  - `final revealEnabled = context.knobs.boolean(label: 'Enable password reveal toggle', initialValue: true);`
  - dedupe + apply via `cardState.setRevealPasswordEnabled('passwordField', enabled: revealEnabled)` in
    the `runWhenCardReady` flush; render via `buildOverlayCard(registry: widgetbookCardTypeRegistry)`.
- Register a `@widgetbook.UseCase` builder in `widgetbook/lib/adaptive_cards_use_cases.dart`
  (type `widget_types.InputText`); regenerate with `fvm dart run build_runner build -d`.

### E. Tests

- HostConfig: `test/hostconfig/inputs_config_test.dart` (asserts `config.text.revealPasswordEnabled`
  default `true` when absent; explicit `false` via nested `{'text': {...}}`) + new
  `test/hostconfig/text_input_config_test.dart` (direct `TextInputConfig.fromJson` coverage).
- Overlay/notifier: in `test/riverpod/adaptive_card_document_notifier_test.dart` —
  `setRevealPasswordEnabled` merges into `resolvedElementProvider`; clear restores baseline.
- Widget: new `test/inputs/text_password_test.dart` — (a) password obscures text; (b) eye-icon present
  - toggles obscure state when enabled; (c) eye-icon absent when HostConfig disables it; (d) overlay
    override hides/shows the icon. Reuse `getTestWidgetFromMap()`.
- Optional golden following `test/inputs/golden_input_text_regex_test.dart`.

### F. Docs + changelog (architecture-doc-sync gate)

- `packages/flutter_adaptive_cards_fs/CHANGELOG.md` → bullet under `## [Unreleased]`.
- `docs/form-inputs.md` → password style + reveal toggle + precedence.
- `docs/hostconfig.md` → document `inputs.text.revealPasswordEnabled` (on `TextInputConfig`, **non-standard**) + `FallbackConfigs.inputsConfig`.
- `docs/overlay-properties-by-type.md` → add `revealPasswordEnabled` to the `Input.Text` row.
- `docs/reactive-riverpod.md` → add `revealPasswordEnabled` to the overlay-field list; note it is
  preserved on reset.
- `docs/Implementation-Status.md` → Password style now supported on Input.Text.

## Critical files

| Area             | File                                                                                       |
| ---------------- | ------------------------------------------------------------------------------------------ |
| Widget + icon    | `packages/flutter_adaptive_cards_fs/lib/src/cards/inputs/text.dart`                        |
| Fallback default | `packages/flutter_adaptive_cards_fs/lib/src/hostconfig/fallback_configs.dart`              |
| HostConfig prop  | `packages/flutter_adaptive_cards_fs/lib/src/hostconfig/inputs_config.dart`                 |
| HostConfig sub   | `packages/flutter_adaptive_cards_fs/lib/src/hostconfig/text_input_config.dart` (new)       |
| Overlay model    | `packages/flutter_adaptive_cards_fs/lib/src/riverpod/adaptive_card_document.dart`          |
| Overlay setter   | `packages/flutter_adaptive_cards_fs/lib/src/riverpod/adaptive_card_document_notifier.dart` |
| Resolved merge   | `packages/flutter_adaptive_cards_fs/lib/src/riverpod/providers.dart`                       |
| Resolved getter  | `packages/flutter_adaptive_cards_fs/lib/src/resolved_input_state.dart`                     |
| Public facade    | `packages/flutter_adaptive_cards_fs/lib/src/flutter_raw_adaptive_card.dart`                |
| Widgetbook page  | `widgetbook/lib/input_text_password_overlay_page.dart` (+ sample JSON, use-case reg)       |

## Verification

```bash
# Repo root
fvm flutter analyze

# Main library
cd packages/flutter_adaptive_cards_fs
fvm flutter test --exclude-tags=golden       # + golden run if golden test added

# Widgetbook codegen + analyze
cd ../../widgetbook
fvm dart run build_runner build -d
fvm flutter analyze
```

Manual check: run widgetbook, open the new Input.Text password demo, confirm characters are obscured,
the eye-icon toggles visibility, and the "Enable password reveal toggle" knob shows/hides the icon at
runtime (overlay path). Run the full library suite (plan-completion gate) before claiming done.
