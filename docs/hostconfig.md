# HostConfig

**Status**: ✅ Current | **Category**: Architecture & Testing

HostConfig is the Adaptive Cards platform contract for colors, typography, spacing, and layout defaults. This document covers **runtime color fallbacks** (theme-derived), the **resolution pipeline**, and **serialization test requirements**.

Related docs:

- [adaptive-style.md](./adaptive-style.md) — full style pipeline and inheritance
- [Architecture-Overview.md](./Architecture-Overview.md) — where HostConfig fits in the monorepo
- `.agents/skills/adaptive-cards-hostconfig-theme/SKILL.md` — agent playbook for styling work

Official spec: [HostConfig explorer](https://adaptivecards.io/explorer/HostConfig.html)

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

| Input | Source | Purpose |
| --- | --- | --- |
| `HostConfigs.light` / `.dark` | Host-provided JSON or empty `HostConfig()` | Explicit platform palette (Teams, Bot Framework, custom) |
| `ThemeColorFallbacks` | `Theme.of(context)` at card build time | Color defaults when HostConfig omits a section or property |

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

| HostConfig area | Theme source |
| --- | --- |
| `containerStyles.default` background | `colorScheme.surface` |
| `containerStyles.emphasis` background | `colorScheme.surfaceContainerHighest` |
| `containerStyles.good` background | `colorScheme.tertiaryContainer` |
| `containerStyles.attention` background | `colorScheme.errorContainer` |
| `containerStyles.accent` background | `colorScheme.primaryContainer` |
| `containerStyles.warning` background | `Color.alphaBlend(warning × 25%, surface)` where `warning = lerp(tertiary, error, 0.45)` |
| Foreground semantic colors (`default`, `accent`, `good`, `warning`, `attention`, …) | `onSurface`, `primary`, `tertiary`, lerped warning, `error`, etc. |
| Subtle foreground (`isSubtle: true`) | base color at **70% opacity** (`_subtleAlpha = 0.7`, AC-style) |
| `progressColors` | `tertiary`, lerped warning, `error`, `primary`, `outline` |
| Progress track background | `surfaceContainerHighest` |
| `chartColors.defaultPalette` | `[primary, secondary, tertiary, error, …containers, outline]` |
| `separator.lineColor` | `outline` (hex-encoded) |
| `badgeStyles` filled/tint | container + on-surface variant roles |

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

| Factory | Default source |
| --- | --- |
| `FontColorConfig.fromJson` | `ThemeColorFallbacks.forParsing.foregroundColors.defaultColor` |
| `ForegroundColorsConfig.fromJson` | per-token defaults from `ThemeColorFallbacks.forParsing.foregroundColors` |
| `ContainerStyleConfig.fromJson` | style-specific defaults from `ThemeColorFallbacks.forParsing.containerStyles` |
| `ContainerStylesConfig.fromJson` | optional `colorDefaults:` parameter |
| `HostConfig.fromJson` | optional `theme:` parameter → `ThemeColorFallbacks(theme ?? ThemeData())` |

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

| File | Role |
| --- | --- |
| `lib/src/hostconfig/host_config.dart` | `HostConfig`, `HostConfigs`, `AdaptiveCardBrightnessMode` |
| `lib/src/hostconfig/theme_color_fallbacks.dart` | Theme-derived color defaults |
| `lib/src/hostconfig/fallback_configs.dart` | Static non-color defaults |
| `lib/src/reference_resolver.dart` | Resolution facade; requires `colorFallbacks` |
| `lib/src/flutter_raw_adaptive_card.dart` | Creates resolver + `ProviderScope` overrides |
| `lib/src/hostconfig/host_config_schema.json` | JSON schema reference |

---

## Serialization test requirements

Verify JSON deserialization for every HostConfig entity and that objects conform to `packages/flutter_adaptive_cards_fs/lib/src/hostconfig/host_config_schema.json`.

### Scope

- **Source classes**: `packages/flutter_adaptive_cards_fs/lib/src/hostconfig/` (excluding `host_config.dart` aggregator-only tests where entity tests suffice)
- **Test directory**: `packages/flutter_adaptive_cards_fs/test/hostconfig/`

### Conventions

One test file per entity, mirroring the Dart file name:

| Entity | Test file | JSON fixture |
| --- | --- | --- |
| `font_color_config.dart` | `font_color_config_test.dart` | `font_color_config.json` |
| `container_styles_config.dart` | `container_styles_config_test.dart` | `container_styles_config.json` |
| … | `{entity}_test.dart` | `{entity}.json` |

Each entity test should:

1. Load the associated JSON file from disk (not an inline map/string in the test body)
2. Deserialize into the HostConfig type via `fromJson`
3. Assert individual properties in the same test

Additional checks:

- JSON fixtures produce valid HostConfig objects
- Property values match the fixture
- Empty `{}` fixtures resolve to **theme-derived** color defaults (see `ThemeColorFallbacks` tests in `fallback_configs_test.dart`)

### Running tests

From `packages/flutter_adaptive_cards_fs`:

```bash
fvm flutter test test/hostconfig/
fvm flutter test --exclude-tags=golden
```

---

## Verification checklist (theme fallback change)

- [ ] Empty `HostConfigs()` card background matches `Theme.of(context).colorScheme.surface` in light and dark
- [ ] Explicit HostConfig JSON colors override theme fallbacks
- [ ] `HostConfig.fromJson(..., theme: ThemeData.dark())` empty container styles use dark scheme defaults
- [ ] `ReferenceResolver` tests pass `colorFallbacks: ThemeColorFallbacks(ThemeData.light())` (or appropriate theme)
- [ ] Progress/badge/chart/separator resolution uses resolver fallbacks, not removed static color fields
