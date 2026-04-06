---
name: adaptive-cards-hostconfig-theme
description: >
  How AdaptiveCards HostConfig maps to Flutter rendering, how ReferenceResolver
  bridges the two, how light/dark themes are structured, and how elements read
  theme-aware colors, fonts, and spacing. Use this before modifying styling,
  colors, spacing, or HostConfig parsing in any element.
---

# HostConfig / Theme Integration Skill

## Overview

Adaptive Cards theming is driven by a JSON **HostConfig** object — a platform
developer's contract that defines colors, font sizes, spacing, and more.
This project maps that HostConfig object to Flutter rendering through two
central abstractions:

```
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

| File | Purpose |
|---|---|
| `lib/src/hostconfig/host_config.dart` | `HostConfig` + `HostConfigs` classes |
| `lib/src/reference_resolver.dart` | `ReferenceResolver` — all resolution logic |
| `lib/src/hostconfig/fallback_configs.dart` | Hardcoded defaults used when HostConfig is absent |
| `lib/src/hostconfig/*.dart` | Typed config classes for each subsection |
| `lib/src/riverpod_providers.dart` | `styleReferenceResolverProvider` Riverpod provider |
| `lib/src/flutter_raw_adaptive_card.dart` | Where `ReferenceResolver` is created and scoped |

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

> **Known limitation:** `HostConfigs.current` is always set to `light` in the
> constructor. Dark mode switching is structurally supported but not yet
> automatically driven by `MediaQuery.platformBrightness`. This is a future
> enhancement opportunity.

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
  // ... other subsections
}
```

---

## How `ReferenceResolver` is Created and Distributed

In `RawAdaptiveCardState.initState()`:
```dart
_resolver = ReferenceResolver(hostConfigs: widget.hostConfigs);
```

In `RawAdaptiveCardState.build()`, it is injected into the
`ProviderScope` that wraps all element widgets:
```dart
return ProviderScope(
  overrides: [
    styleReferenceResolverProvider.overrideWithValue(_resolver),
    // ... other providers
  ],
  child: Card(color: backgroundColor, child: child),
);
```

**Containers** use `copyWith()` to create a child resolver with the current
container style, maintaining proper style inheritance down the tree:
```dart
final childResolver = resolver.copyWith(style: 'emphasis');
```

---

## Reading the Resolver in an Element

Inside any element's `build()` method, get the resolver via Riverpod:

```dart
import 'package:flutter_adaptive_cards_fs/src/riverpod_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@override
Widget build(BuildContext context) {
  final resolver = ProviderScope.containerOf(context)
      .read(styleReferenceResolverProvider);

  // Now use resolver.resolve*() methods...
}
```

> **Never** call `ProviderScope.containerOf(context).watch(...)` — always use
> `read()`. Elements rebuild via `setState`, not reactive watching.

---

## `ReferenceResolver` Method Reference

### Colors

#### Foreground (Text) Colors

AC defines semantic color names for text, resolved through the container
style's `ForegroundColorsConfig`:

```dart
// Semantic color names: 'default', 'dark', 'light', 'accent',
//                        'good', 'warning', 'attention'
// isSubtle: true gives the 70% opacity variant

Color? color = resolver.resolveContainerForegroundColor(
  style: adaptiveMap['color'] as String?,  // JSON "color" property
  isSubtle: adaptiveMap['isSubtle'] as bool? ?? false,
);
```

Resolution priority:
1. Explicitly passed `style` (if not `'default'`)
2. `currentContainerStyle` (inherited from parent container's resolver)
3. The `'default'` container style foreground colors
4. `FallbackConfigs.containerStylesConfig` if HostConfig is absent

#### Container Background Colors

Container `"style"` property maps to background colors:

```dart
// Container style names: 'default', 'emphasis', 'good',
//                         'attention', 'warning', 'accent'
Color? bg = resolver.resolveContainerBackgroundColor(style: 'emphasis');

// Smart version: returns null if backgroundImage is set or style is null
// (lets the container be transparent to its parent)
Color? bg2 = resolver.resolveContainerBackgroundColorIfNoBackgroundImage(
  context: context,
  style: adaptiveMap['style'] as String?,
  backgroundImageUrl: adaptiveMap['backgroundImage'] as String?,
);
```

#### Button Colors (Material Theme-Derived)

Action buttons do **not** use HostConfig colors — they use `Theme.of(context)`:

```dart
// Action "style" values: 'default', 'positive', 'destructive'
Color? bg = resolver.resolveButtonBackgroundColor(
  context: context,
  style: adaptiveMap['style'] as String?,
);
// 'default'     → colorScheme.primary
// 'positive'    → colorScheme.secondary
// 'destructive' → colorScheme.error

Color? fg = resolver.resolveButtonForegroundColor(
  context: context,
  style: adaptiveMap['style'] as String?,
);
// 'default'     → colorScheme.onPrimary
// 'positive'    → colorScheme.onSecondary
// 'destructive' → colorScheme.onError
```

> This is where Flutter's Material 3 `ThemeData` directly affects card rendering.
> Setting `colorScheme.primary` in the host app's theme changes button appearances.

### Typography

```dart
// Font size — 'default', 'small', 'medium', 'large', 'extraLarge'
double size = resolver.resolveFontSize(
  context: context,
  sizeString: adaptiveMap['size'] as String?,
);

// Font weight — 'default', 'lighter', 'bolder'
FontWeight weight = resolver.resolveFontWeight(
  adaptiveMap['weight'] as String?,
);

// Font type — 'default', 'monospace' (currently both return theme font)
String? family = resolver.resolveFontType(
  context,
  adaptiveMap['fontType'] as String?,
);
```

Fallback font size values (from `FallbackConfigs.fontSizesConfig`):

| AC Name | Default px |
|---|---|
| small | 10 |
| **default** | 12 |
| medium | 14 |
| large | 18 |
| extraLarge | 22 |

### Spacing

AC's `"spacing"` JSON property controls vertical/horizontal gaps between elements:

```dart
// Spacing values: 'none', 'small', 'default', 'medium', 'large',
//                 'extraLarge', 'padding'
double gap = resolver.resolveSpacing(adaptiveMap['spacing'] as String?);

// Or use SpacingsConfig.resolveSpacing() directly:
double gap = SpacingsConfig.resolveSpacing(
  resolver.getSpacingsConfig(),
  spacing,
);
```

Fallback spacing values (from `FallbackConfigs.spacingsConfig`):

| AC Name | Default px |
|---|---|
| none | 0 |
| small | 4 |
| **default** | 4 |
| medium | 8 |
| large | 16 |
| extraLarge | 32 |
| padding | 20 |

### Separators

```dart
double thickness = resolver.resolveSeparatorThickness(); // default: 1.0
Color color = resolver.resolveSeparatorColor();          // default: Colors.grey.shade300
```

### Alignment

```dart
// HorizontalAlignment: 'left', 'center', 'right'
Alignment align = resolver.resolveAlignment(
  adaptiveMap['horizontalAlignment'] as String?,
);

// CrossAxisAlignment variant
CrossAxisAlignment cross = resolver.resolveHorzontalCrossAxisAlignment(
  adaptiveMap['horizontalAlignment'] as String?,
);

// MainAxisAlignment (horizontal)
MainAxisAlignment main = resolver.resolveHorizontalMainAxisAlignment(
  adaptiveMap['horizontalAlignment'] as String?,
);

// VerticalContentAlignment: 'top', 'center', 'bottom'
MainAxisAlignment vertical = resolver.resolveVerticalMainAxisContentAlginment(
  adaptiveMap['verticalContentAlignment'] as String?,
);

// TextAlign: 'left', 'center', 'right'
TextAlign ta = resolver.resolveTextAlign(adaptiveMap['horizontalAlignment'] as String?);
```

### Text Wrapping

```dart
// Respects both "wrap" (bool) and "maxLines" (int) JSON properties
int maxLines = resolver.resolveMaxLines(
  wrap: adaptiveMap['wrap'] as bool?,
  maxLines: adaptiveMap['maxLines'] as int?,
);
// wrap=false → always 1; wrap=true → maxLines ?? 1
```

---

## The Color Model: `ForegroundColorsConfig` → `FontColorConfig`

The color resolution chain for foreground text:

```
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

AdaptiveCardsRoot.asset(
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
2. **`FallbackConfigs` static value** — hardcoded in `fallback_configs.dart`
3. **Flutter `Theme.of(context)`** — only for action buttons (no HostConfig equivalent)

The `FallbackConfigs` class is the "opinion of last resort" and represents a
reasonable Material-adjacent appearance. It is intentionally not Material 3
`ColorScheme`-aware for most properties, which is a known gap.

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
`AdaptiveCardsRoot` that has an injected `HostConfigs`:
```dart
// See test/host_config_test.dart for the established pattern
```
