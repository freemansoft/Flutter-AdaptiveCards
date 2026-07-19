---
doc_type: explanation
---

# HostConfig

**Status**: ✅ Current | **Category**: Explanation (`doc_type: explanation`)

HostConfig is the Adaptive Cards platform contract for colors, typography, spacing, and layout defaults. This document covers **JSON model parsing**, **runtime color fallbacks** (theme-derived), and the **resolution pipeline**. How to write and run the serialization tests: [hostconfig-testing.md](hostconfig-testing.md).

Related docs:

- [adaptive-style.md](./adaptive-style.md) — style inheritance pipeline (`ChildStyler`, resolver lifecycle diagrams)
- [Architecture-Overview.md](./Architecture-Overview.md) — where HostConfig fits in the monorepo
- `.agents/skills/adaptive-cards-hostconfig-theme/SKILL.md` — agent playbook for styling work

Official spec: [HostConfig explorer](https://adaptivecards.io/explorer/HostConfig.html)

---

## Non-standard HostConfig extensions

This project occasionally adds HostConfig properties that are **not part of the official Adaptive Cards HostConfig schema**. These custom extensions exist to support platform-specific or UX behaviours the spec does not address.

Convention: every non-standard property is flagged with a **Non-standard** callout in both its Dart `///` doc comment and in this section.

### `inputs.text.revealPasswordEnabled` _(Non-standard)_

**Type:** `bool` | **Default:** `true` (`FallbackConfigs.inputsConfig.text.revealPasswordEnabled`)

When `true`, `Input.Text` fields whose `style` is `"password"` render a show/hide eye-icon toggle alongside the field. When `false`, no toggle is shown and the field remains masked.

This property is nested under `inputs.text` (a `TextInputConfig` object exposed as `InputsConfig.text`) rather than directly on `inputs`. Example JSON:

```json
"inputs": { "text": { "revealPasswordEnabled": true } }
```

A per-element overlay (`revealPasswordEnabled`) can override this at runtime.

Resolution precedence (highest wins):

1. Per-element overlay (`revealPasswordEnabled` in the document notifier)
2. `HostConfig` value (`inputs.text.revealPasswordEnabled` in JSON)
3. `FallbackConfigs.inputsConfig.text.revealPasswordEnabled` (`true`)

Source files: `lib/src/hostconfig/inputs_config.dart`, `lib/src/hostconfig/text_input_config.dart`, `lib/src/hostconfig/fallback_configs.dart`.

### `inputs.choiceSet.enableSearch` _(Non-standard)_

**Type:** `bool` | **Default:** `true` (`FallbackConfigs.inputsConfig.choiceSet.enableSearch`)

Controls the compact single-select `Input.ChoiceSet` dropdown (Material 3 `DropdownMenu`). When `true`, typing a character _jumps to / highlights_ the matching entry while keeping the full list visible — the closest analog to a native HTML `<select>`. When `false`, type-ahead jump is disabled. Maps to `DropdownMenu.enableSearch`.

### `inputs.choiceSet.requestFocusOnTap` _(Non-standard)_

**Type:** `bool?` | **Default:** `null` → platform-aware (`DropdownMenu`'s own default)

Controls whether the compact dropdown takes focus (enabling keyboard type-ahead) when tapped. When `null`, `DropdownMenu` applies its platform-aware default: focusable on desktop (macOS/Linux/Windows) and tap-only on mobile (iOS/Android/Fuchsia) so it does not pop the soft keyboard for a simple dropdown. Set `true`/`false` to force the behavior regardless of platform. Maps to `DropdownMenu.requestFocusOnTap`.

Both properties are nested under `inputs.choiceSet` (a `ChoiceSetConfig` object exposed as `InputsConfig.choiceSet`). Example JSON:

```json
"inputs": { "choiceSet": { "enableSearch": true, "requestFocusOnTap": false } }
```

Resolution precedence (highest wins):

1. `HostConfig` value (`inputs.choiceSet.*` in JSON)
2. `FallbackConfigs.inputsConfig.choiceSet.*` (`enableSearch: true`, `requestFocusOnTap: null`)

Source files: `lib/src/hostconfig/inputs_config.dart`, `lib/src/hostconfig/choice_set_config.dart`, `lib/src/hostconfig/fallback_configs.dart`.

---

## Microsoft Teams HostConfig extensions

Unlike the [Non-standard HostConfig extensions](#non-standard-hostconfig-extensions) above (custom behaviors this project invented), these properties are documented by Microsoft Teams as Adaptive Cards extensions beyond the base schema — see [Cards format reference](https://learn.microsoft.com/en-us/microsoftteams/platform/task-modules-and-cards/cards/cards-format?tabs=adaptive-md%2Cdesktop%2Cdesktop1%2Cdesktop2%2Cconnector-html).

### `cornerRadius` (`roundedCorners` element property)

**Type:** `double?` | **Default:** `8` (`FallbackConfigs.cornerRadius`)

`roundedCorners` is a Teams Adaptive Cards element property (`"roundedCorners": true`), documented as supported on `Container`, `ColumnSet`, `Column`, `Table`, and `Image`. This package currently wires it on **`Container`, `ColumnSet`, and `Column`**; `Table` and `Image` are tracked separately. The corner radius applied when `roundedCorners` is set is a single HostConfig-wide default — `cornerRadius` is a top-level scalar, not a per-element or per-style value.

Example JSON:

```json
{ "cornerRadius": 12 }
```

```json
{ "type": "Container", "roundedCorners": true, "items": [] }
```

Resolution precedence (highest wins):

1. `HostConfig` value (`cornerRadius` in JSON, top-level)
2. `FallbackConfigs.cornerRadius` (`8`)

Source files: `lib/src/hostconfig/host_config.dart` (`HostConfig.cornerRadius`, parsed in `HostConfig.fromJson`), `lib/src/hostconfig/fallback_configs.dart` (`FallbackConfigs.cornerRadius`), `lib/src/reference_resolver.dart` (`ReferenceResolver.resolveCornerRadius()`), `lib/src/cards/containers/container.dart` (`AdaptiveContainerState.build`), `lib/src/cards/containers/column_set.dart` (`AdaptiveColumnSetState.build`), `lib/src/cards/containers/column.dart` (`AdaptiveColumnState.build`).

---

## Architecture overview

HostConfig JSON is parsed into typed Dart classes under `packages/flutter_adaptive_cards_fs/lib/src/hostconfig/`. At render time, `ReferenceResolver` bridges HostConfig values to Flutter widgets.

```txt
HostConfigs (light + dark)
        │
        ▼
  HostConfig.current  ◄── brightness from Theme.of(context) when mode is auto
        │
        ▼
  ReferenceResolver
    ├── hostConfigs     explicit JSON values (when present)
    └── colorFallbacks  ThemeColorFallbacks from ambient ThemeData
        │
        ▼
  Element widgets (via styleReferenceResolverProvider)
```

Two independent theme inputs matter:

| Input                         | Source                                     | Purpose                                                    |
| ----------------------------- | ------------------------------------------ | ---------------------------------------------------------- |
| `HostConfigs.light` / `.dark` | Host-provided JSON or empty `HostConfig()` | Explicit platform palette (Teams, Bot Framework, custom)   |
| `ThemeColorFallbacks`         | `Theme.of(context)` at card build time     | Color defaults when HostConfig omits a section or property |

Non-color defaults (spacing, font sizes, image sizes, progress sizes, chart layout dimensions) remain in `FallbackConfigs` as static values — they are not derived from `ColorScheme`.

---

## Theme-derived color fallbacks

### Problem

Previously, `FallbackConfigs` hardcoded colors (`Colors.white`, `Colors.black`, fixed hex semantic container tints). Empty `HostConfigs()` — used by Widgetbook, tests, and sample apps — always rendered a **light** card surface even when the Flutter app was in dark mode.

### Design

Introduce **`ThemeColorFallbacks`**, a small factory that maps Material 3 `ColorScheme` roles to Adaptive Cards semantic names. Color fallbacks are **instance data** tied to the ambient Flutter theme, not static constants.

**Resolution order** (unchanged intent, updated source for step 2):

1. **HostConfig value** — property set in the active `HostConfig` (`hostConfigs.current`)
2. **`ThemeColorFallbacks`** — derived from `ThemeData.colorScheme` for the current build
3. **Flutter `Theme.of(context)`** — action buttons only (no HostConfig equivalent; unchanged)

Action buttons continue to use `colorScheme.primary` / `secondary` / `error` via `resolveButtonBackgroundColor(context: …)`.

### `ThemeColorFallbacks` mapping

File: `packages/flutter_adaptive_cards_fs/lib/src/hostconfig/theme_color_fallbacks.dart`

| HostConfig area                                                                     | Theme source                                                                             |
| ----------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------- |
| `containerStyles.default` background                                                | `colorScheme.surface`                                                                    |
| `containerStyles.emphasis` background                                               | `colorScheme.surfaceContainerHighest`                                                    |
| `containerStyles.good` background                                                   | `colorScheme.tertiaryContainer`                                                          |
| `containerStyles.attention` background                                              | `colorScheme.errorContainer`                                                             |
| `containerStyles.accent` background                                                 | `colorScheme.primaryContainer`                                                           |
| `containerStyles.warning` background                                                | `Color.alphaBlend(warning × 25%, surface)` where `warning = lerp(tertiary, error, 0.45)` |
| Foreground semantic colors (`default`, `accent`, `good`, `warning`, `attention`, …) | `onSurface`, `primary`, `tertiary`, lerped warning, `error`, etc.                        |
| Subtle foreground (`isSubtle: true`)                                                | base color at **70% opacity** (`_subtleAlpha = 0.7`, AC-style)                           |
| `progressColors`                                                                    | `tertiary`, lerped warning, `error`, `primary`, `outline`                                |
| Progress track background                                                           | `surfaceContainerHighest`                                                                |
| `chartColors.defaultPalette`                                                        | `[primary, secondary, tertiary, error, …containers, outline]`                            |
| `separator.lineColor`                                                               | `outline` (hex-encoded)                                                                  |
| `badgeStyles` filled/tint                                                           | container + on-surface variant roles                                                     |

Named Teams chart palettes (`kChartCategoricalPalette`, token resolution via `resolveChartColorToken`) are **unchanged** — they are explicit palette families, not HostConfig fallbacks.

### Runtime wiring

`RawAdaptiveCardState._updateResolver()` creates the resolver on every theme/brightness change:

```dart
_resolver = ReferenceResolver(
  hostConfigs: widget.hostConfigs,
  colorFallbacks: ThemeColorFallbacks(Theme.of(context)),
);
```

`ReferenceResolver` stores `colorFallbacks` and uses it anywhere color fallbacks were previously read from static `FallbackConfigs` fields. `copyWith()` preserves the same `colorFallbacks` instance.

Progress elements call `styleResolver.resolveProgressColor(color)` instead of the static `ProgressColorsConfig.resolveProgressColor` without fallbacks.

### JSON parsing defaults

When HostConfig JSON is deserialized and color properties are missing, parsers use theme-derived defaults:

| Factory                           | Default source                                                                |
| --------------------------------- | ----------------------------------------------------------------------------- |
| `FontColorConfig.fromJson`        | `ThemeColorFallbacks.forParsing.foregroundColors.defaultColor`                |
| `ForegroundColorsConfig.fromJson` | per-token defaults from `ThemeColorFallbacks.forParsing.foregroundColors`     |
| `ContainerStyleConfig.fromJson`   | style-specific defaults from `ThemeColorFallbacks.forParsing.containerStyles` |
| `ContainerStylesConfig.fromJson`  | optional `colorDefaults:` parameter                                           |
| `HostConfig.fromJson`             | optional `theme:` parameter → `ThemeColorFallbacks(theme ?? ThemeData())`     |

`ThemeColorFallbacks.forParsing` is a lazy singleton using `ThemeData()` for parse-time-only contexts (unit tests, offline JSON load without a widget tree).

### `FallbackConfigs` (non-color only)

File: `packages/flutter_adaptive_cards_fs/lib/src/hostconfig/fallback_configs.dart`

Retains static defaults for spacing, font sizes/weights, image sizes, progress **sizes**, and chart **layout** — no color fields.

---

## Brightness selection

`HostConfigs` holds separate `light` and `dark` `HostConfig` objects. `RawAdaptiveCard` sets `hostConfigs.current` from:

- `AdaptiveCardBrightnessMode.auto` → `Theme.of(context).brightness`
- `.light` / `.dark` → forced HostConfig side

Color **fallbacks** always follow the ambient `ThemeData` passed to `ThemeColorFallbacks(Theme.of(context))`, which aligns with auto mode. When forcing light/dark HostConfig via `brightnessMode`, provide matching explicit HostConfig JSON for both sides if platform colors must differ from Material defaults.

---

## Widgetbook integration

Widgetbook sample pages use `HostConfigs()` (empty). Card surface color now follows:

1. **Material Theme addon** → `Theme.of(context)` inside the use-case tree
2. **`ThemeColorFallbacks`** → `colorScheme.surface` for the root card background

The Widgetbook `appBuilder` must forward the Theme addon selection to `MaterialApp` (`theme`, `darkTheme`, `themeMode`) so app-level widgets and the card subtree share the same brightness. See `widgetbook/lib/main.dart` (`_widgetbookAppBuilder`).

---

## Key files

| File                                            | Role                                                      |
| ----------------------------------------------- | --------------------------------------------------------- |
| `lib/src/hostconfig/host_config.dart`           | `HostConfig`, `HostConfigs`, `AdaptiveCardBrightnessMode` |
| `lib/src/hostconfig/theme_color_fallbacks.dart` | Theme-derived color defaults                              |
| `lib/src/hostconfig/fallback_configs.dart`      | Static non-color defaults                                 |
| `lib/src/reference_resolver.dart`               | Resolution facade; requires `colorFallbacks`              |
| `lib/src/flutter_raw_adaptive_card.dart`        | Creates resolver + `ProviderScope` overrides              |
| `lib/src/hostconfig/host_config_schema.json`    | JSON schema reference                                     |

---

## Testing

Serialization test requirements (one fixture per HostConfig entity, conventions, running the
tests) and the theme-fallback verification checklist live in the how-to companion:
[hostconfig-testing.md](hostconfig-testing.md).
