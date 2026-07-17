---
name: adaptive-cards-hostconfig-theme
description: >
  Use before modifying styling, colors, spacing, fonts, or HostConfig parsing in
  any element. Explains how Adaptive Cards HostConfig maps to Flutter rendering,
  how ReferenceResolver bridges the two, and how light/dark themes are
  structured.
---

# HostConfig / Theme Integration Skill

## Overview

Adaptive Cards theming is driven by a JSON **HostConfig** object — a platform
developer's contract that defines colors, font sizes, spacing, and more.
This project maps that HostConfig object to Flutter rendering through two
central abstractions:

```txt
HostConfigs  ──(contains)──►  HostConfig (light)
             ──(contains)──►  HostConfig (dark)
                                   │
                                   ▼
                          ReferenceResolver
                    (the bridge used by all elements)
```

The `ReferenceResolver` is created in `RawAdaptiveCardState` and exposed to
every element widget via a Riverpod `Provider` override.

---

## Key Files

| File                                       | Purpose                                                             |
| ------------------------------------------ | ------------------------------------------------------------------- |
| `lib/src/hostconfig/host_config.dart`      | `HostConfig` + `HostConfigs` classes                                |
| `lib/src/reference_resolver.dart`          | `ReferenceResolver` — HostConfig/style resolution only              |
| `lib/src/hostconfig/fallback_configs.dart` | Hardcoded defaults used when HostConfig is absent                   |
| `lib/src/hostconfig/*.dart`                | Typed config classes for each subsection                            |
| `lib/src/riverpod/providers.dart`          | Card-scoped Riverpod providers (registries, resolver, document)     |
| `lib/src/flutter_raw_adaptive_card.dart`   | Where `ReferenceResolver` is created and scoped via `ProviderScope` |

---

## The Two-Level Config Structure

### `HostConfigs` — Light + Dark Wrapper

```dart
class HostConfigs {
  final HostConfig light;   // used for light mode rendering
  final HostConfig dark;    // used for dark mode rendering
  late HostConfig current;  // set to light by default in constructor
}
```

> **Brightness:** `RawAdaptiveCardState._updateResolver()` sets `HostConfigs.current`
> from `Theme.of(context).brightness` when `brightnessMode` is `auto` (default).
> Hosts can force light or dark with `AdaptiveCardBrightnessMode.light` / `.dark`.

### `HostConfig` — The AC Spec Object

`HostConfig` is a Dart representation of the
[Adaptive Cards HostConfig JSON schema](https://adaptivecards.io/explorer/HostConfig.html).
All properties are nullable — if absent, `ReferenceResolver` falls back to
`FallbackConfigs`.

```dart
class HostConfig {
  final String? fontFamily;
  final ForegroundColorsConfig? foregroundColors;  // text colors by semantic name
  final ContainerStylesConfig? containerStyles;     // container bg + fg colors
  final FontSizesConfig? fontSizes;                 // small/medium/large/extraLarge
  final FontWeightsConfig? fontWeights;             // lighter/default/bolder
  final SpacingsConfig? spacing;                    // none/small/medium/large/...
  final SeparatorConfig? separator;                 // divider thickness + color
  final ImageSizesConfig? imageSizes;               // small/medium/large px values
  final ActionsConfig? actions;                     // button layout, spacing
  final InputsConfig? inputs;                       // label/error message styling
  final BadgeStylesConfig? badgeStyles;             // badge filled/tint colors
  final ProgressSizesConfig? progressSizes;         // progress bar dimensions
  final ProgressColorsConfig? progressColors;       // progress bar colors
  final ChartColorsConfig? chartColors;            // chart palettes and defaults
  // ... other subsections
}
```

---

## How `ReferenceResolver` is Created and Distributed

In `RawAdaptiveCardState._updateResolver()` (called from `initState` / `didUpdateWidget`):

```dart
_resolver = ReferenceResolver(
  hostConfigs: widget.hostConfigs,
  colorFallbacks: ThemeColorFallbacks(Theme.of(context)),
);
```

Registries are **not** passed to `ReferenceResolver`. They are supplied separately via Riverpod overrides in `build()`:

```dart
return ProviderScope(
  overrides: [
    cardTypeRegistryProvider.overrideWithValue(widget.cardTypeRegistry),
    actionTypeRegistryProvider.overrideWithValue(widget.actionTypeRegistry),
    styleReferenceResolverProvider.overrideWithValue(_resolver),
    // ... document and card-state providers
  ],
  child: Card(color: backgroundColor, child: child),
);
```

**Containers** use **`ChildStyler`** to override `styleReferenceResolverProvider`
for descendants with inherited foreground context and alignment:

```dart
// ChildStyler (in additional.dart) — simplified
final childResolver = parent.copyWith(
  inheritedContainerStyle: ReferenceResolver.inheritedContainerStyleForChildren(
    parentInherited: parent.inheritedContainerStyle,
    ownContainerStyle: adaptiveMap['style'] as String?,
  ),
  inheritedHorizontalAlignment:
      ReferenceResolver.inheritedHorizontalAlignmentForChildren(
    parentInherited: parent.inheritedHorizontalAlignment,
    ownAlignment: adaptiveMap['horizontalAlignment'] as String?,
  ),
);
```

Container **background** uses only the element's own `style` JSON.
**Foreground** palette uses `inheritedContainerStyle` on the scoped resolver.

See [Style inheritance data flow](../../../docs/adaptive-style.md#style-inheritance-data-flow).

---

## Reading the Resolver in an Element

Inside any element `State` with `ProviderScopeMixin`, use `styleResolver`:

```dart
@override
Widget build(BuildContext context) {
  final resolver = styleResolver;

  // Now use resolver.resolve*() methods...
}
```

Stateless helpers can read the resolver from the card-scoped container:

```dart
final resolver = ProviderScope.containerOf(context)
    .read(styleReferenceResolverProvider);
```

Elements rebuild via `setState` or `ref.watch`, not by listening to an inherited widget.

---

## `ReferenceResolver` Method Reference

The full method-by-method API — every color, font, spacing, separator, chart,
and alignment call with its accepted values and fallback tables — lives in
[`references/reference-resolver-api.md`](references/reference-resolver-api.md).
Read the relevant section there when you need the exact resolver call; the
architecture, color model, fallback strategy, and testing guidance below stay in
this skill.

---

## The Color Model: `ForegroundColorsConfig` → `FontColorConfig`

The color resolution chain for foreground text:

```txt
ContainerStylesConfig
  └── ContainerStyleConfig (for 'default' or 'emphasis')
        └── ForegroundColorsConfig
              └── FontColorConfig (for 'default', 'accent', 'good', etc.)
                    ├── defaultColor: Color   ← full opacity
                    └── subtleColor:  Color   ← ~70% opacity (isSubtle: true)
```

Colors in JSON are hex strings in `#RRGGBB` or `#AARRGGBB` format:

```json
{ "default": "#FF000000", "subtle": "#B2000000" }
```

`FontColorConfig._parseColor()` handles both formats.

---

## Providing a Custom HostConfig

### From a Dart Object

```dart
final myConfig = HostConfig(
  fontSizes: FontSizesConfig(
    small: 11,
    defaultSize: 14,
    medium: 16,
    large: 20,
    extraLarge: 24,
  ),
  containerStyles: ContainerStylesConfig(
    defaultStyle: ContainerStyleConfig(
      backgroundColor: Colors.white,
      foregroundColors: ForegroundColorsConfig(
        defaultColor: FontColorConfig(
          defaultColor: Colors.black87,
          subtleColor: Colors.black54,
        ),
        accent: FontColorConfig(
          defaultColor: Colors.blue,
          subtleColor: Colors.blue.withAlpha(128),
        ),
        // ... other colors
      ),
    ),
    emphasis: ContainerStyleConfig(
      backgroundColor: const Color(0xFFF5F5F5),
      foregroundColors: /* same pattern */,
    ),
  ),
);

AdaptiveCardsCanvas.asset(
  assetPath: 'assets/my_card.json',
  hostConfigs: HostConfigs(light: myConfig, dark: myDarkConfig),
);
```

### From a JSON String (HostConfig Spec)

```dart
import 'dart:convert';

final Map<String, dynamic> json = jsonDecode(hostConfigJsonString);
final config = HostConfig.fromJson(json);
final hostConfigs = HostConfigs(light: config);
```

The JSON schema is documented in `lib/src/hostconfig/host_config_schema.json`.
The official spec is at [adaptivecards.io/explorer/HostConfig.html](https://adaptivecards.io/explorer/HostConfig.html).

---

## Fallback Strategy

Every `ReferenceResolver` method follows this fallback chain:

1. **HostConfig value** — from the `HostConfig` object if the property is set
2. **`ThemeColorFallbacks`** — color defaults derived from `ThemeData.colorScheme` (see [docs/hostconfig.md](../../../docs/hostconfig.md))
3. **`FallbackConfigs` static value** — non-color defaults only (spacing, font sizes, …) in `fallback_configs.dart`
4. **Flutter `Theme.of(context)`** — action buttons only (no HostConfig equivalent)

`ReferenceResolver` requires `colorFallbacks: ThemeColorFallbacks(Theme.of(context))`, created in `RawAdaptiveCardState._updateResolver()`.

---

## Testing HostConfig Behavior

Unit tests for config parsing are in `test/hostconfig/`:

```dart
// Testing config parsing (no widget needed)
test('custom font sizes are parsed', () {
  final config = HostConfig.fromJson({
    'fontSizes': {'default': 16, 'large': 22},
  });
  expect(config.fontSizes?.defaultSize, 16);
  expect(config.fontSizes?.large, 22);
  expect(config.fontSizes?.small, FallbackConfigs.fontSizesConfig.small); // fallback
});
```

Widget-level HostConfig tests use `getTestWidgetFromMap` with a custom
`AdaptiveCardsCanvas` that has an injected `HostConfigs`:

```dart
// See test/host_config_test.dart for the established pattern
```
