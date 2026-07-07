---
doc_type: how-to
---

# Input.Text recipes

Task-focused recipes for customizing `Input.Text` fields: character filtering for
phone-style inputs, and the password masking / reveal toggle. These assume you already
know the input runtime model — for overlays, reset semantics, and the full input
reference, see [`form-inputs.md`](form-inputs.md).

## Input.Text — phone style and character filtering

`Input.Text` with `style: "tel"` sets `keyboardType: TextInputType.phone` on the underlying `TextFormField`. This only controls which virtual keyboard appears on iOS/Android; it does **not** filter characters. On desktop or in widget tests (`tester.enterText` bypasses the keyboard entirely), any character can be typed regardless of keyboard type.

There has never been a `FilteringTextInputFormatter` for phone inputs in this codebase. The only formatter applied to all `Input.Text` fields is `LengthLimitingTextInputFormatter(maxLength)`.

**Validation is submit-time only.** The `regex` field in the card JSON is checked inside `TextFormField.validator`, which runs when `Form.validate()` is called at submit. It is not checked keystroke-by-keystroke. The sequence for a phone field with `regex: "^\(\d{3}\) \d{3}-\d{4}$"`:

1. User types `AAA` → accepted into the field, no error shown
2. User submits → `Form.validate()` → regex fails → error message rendered
3. User resumes typing → validation overlays cleared (see [Edit phase](form-inputs.md#input-overlay-architecture))

This matches the Adaptive Cards spec, which specifies `regex` as a validation rule, not an input filter.

**If you want to block non-phone characters at entry time**, add a conditional `FilteringTextInputFormatter` in `text.dart` alongside the existing length formatter:

```dart
inputFormatters: [
  LengthLimitingTextInputFormatter(maxLength),
  if (inputStyle == TextInputType.phone)
    FilteringTextInputFormatter.allow(RegExp(r'[\d\+\-\(\)\. ]')),
],
```

This silently drops any character not matching the allowlist as it is typed. Be aware that `style: "tel"` is optional in the card JSON — a field can carry a phone `regex` without `style: "tel"`, in which case `inputStyle` would be `null` and this guard would not fire. The guard would need to also inspect the `regex` pattern, or be applied unconditionally for fields with any `regex`.

## Input.Text — password masking and reveal toggle

`Input.Text` with `"style": "password"` obscures typed characters using Flutter's `obscureText: true`. This is **client-side only**: the submitted value is always the clear-text string (the overlay `inputValue` / baseline `value` are never encoded). Password fields are forced single-line regardless of `isMultiline`; autocorrect and suggestions are disabled; the system keyboard type is set to `TextInputType.visiblePassword`.

### Eye-icon reveal toggle

An optional eye-icon button in the field suffix lets users temporarily reveal what they typed. Whether the toggle is shown follows a **three-source precedence** (highest wins):

| Priority     | Source                                         | Symbol                                                                                                |
| ------------ | ---------------------------------------------- | ----------------------------------------------------------------------------------------------------- |
| 1 (highest)  | Per-element runtime overlay                    | `ElementOverlay.revealPasswordEnabled` (bool?) via `ResolvedInputState.revealPasswordEnabledOverride` |
| 2            | HostConfig `inputs.text.revealPasswordEnabled` | `TextInputConfig.revealPasswordEnabled` on `InputsConfig.text`                                        |
| 3 (fallback) | `FallbackConfigs.inputsConfig`                 | `FallbackConfigs.inputsConfig.text.revealPasswordEnabled` (defaults `true`)                           |

The widget resolves effective availability as:
`(getInputsConfig() ?? FallbackConfigs.inputsConfig).text.revealPasswordEnabled`
with the overlay checked first by `ResolvedInputState.revealPasswordEnabledOverride`.

The HostConfig field `inputs.text.revealPasswordEnabled` is **non-standard** (not in the Microsoft spec); it lives on the new `TextInputConfig` class nested under `InputsConfig.text`. By default the reveal toggle is enabled for all password fields.

### Overlay and reset behavior

The per-element reveal toggle can be set or cleared at runtime:

- **Set:** `AdaptiveCardDocumentNotifier.setRevealPasswordEnabled(id, enabled)` / `RawAdaptiveCardState.setRevealPasswordEnabled(id, enabled)`
- **Clear:** `AdaptiveCardDocumentNotifier.clearRevealPasswordEnabled(id)` / `RawAdaptiveCardState.clearRevealPasswordEnabled(id)`

Unlike value and validation overlays, `revealPasswordEnabled` is **preserved** (not cleared) by `Action.ResetInputs` / `resetInput` / `resetAllInputs` — the same preservation policy as `isVisible` and typeahead session fields. See [Reset semantics in reactive-riverpod.md](reactive-riverpod.md#reset-semantics).
