# `ReferenceResolver` Method Reference

The method-by-method API for `ReferenceResolver`, split out of the
`adaptive-cards-hostconfig-theme` SKILL so the skill body stays focused on
architecture. Read the relevant section here when you need the exact call for a
color, font, spacing, separator, chart, or alignment value.

Obtain the resolver as described in the skill body — `styleResolver` inside an
element `State` with `ProviderScopeMixin`, or
`ProviderScope.containerOf(context).read(styleReferenceResolverProvider)` from a
stateless helper.

## Contents

- [Colors](#colors) — foreground text, container background, button
- [Typography](#typography)
- [Spacing](#spacing)
- [Separators](#separators)
- [Charts](#charts)
- [Alignment](#alignment)
- [Text Wrapping](#text-wrapping)

> The fallback px tables below mirror `FallbackConfigs` (`fallback_configs.dart`).
> They are copied here for convenience — the source of truth is the Dart file; if
> the two disagree, trust the code.

## Colors

### Foreground (Text) Colors

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

### Container Background Colors

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

### Button Colors (Material Theme-Derived)

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

## Typography

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

| AC Name     | Default px |
| ----------- | ---------- |
| small       | 10         |
| **default** | 12         |
| medium      | 14         |
| large       | 18         |
| extraLarge  | 22         |

## Spacing

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

| AC Name     | Default px |
| ----------- | ---------- |
| none        | 0          |
| small       | 4          |
| **default** | 4          |
| medium      | 8          |
| large       | 16         |
| extraLarge  | 32         |
| padding     | 20         |

## Separators

```dart
// Divider drawn when an element sets "separator": true (see SeparatorElement)
double thickness = resolver.resolveSeparatorThickness();
Color color = resolver.resolveSeparatorColor();

// Raw HostConfig section, if a caller needs both at once
SeparatorConfig? config = resolver.getSeparatorConfig();
```

## Charts

```dart
// Resolves the color palette for charts
List<Color> palette = resolver.resolveChartPalette();

// Resolves a single chart color (hex or semantic 'good'/'warning'/etc.)
Color color = resolver.resolveChartColor(
  adaptiveMap['color'] as String?,
  fallback: Colors.blue,
);
```

### Chart layout (`chartsLayout`)

```dart
final layout = resolver.resolveLineChartLayout();
// Also: resolveBarChartLayout(), resolvePieChartLayout(), resolveDonutChartLayout()
```

JSON example:

```json
{
  "chartsLayout": {
    "line": { "height": 250, "barWidth": 3, "borderColor": "#37434d" },
    "bar": { "height": 250, "barWidth": 16, "barsSpace": 4 },
    "pie": { "height": 200, "sectionRadius": 100 },
    "donut": { "centerSpaceRadius": 40, "sectionRadius": 50 }
  }
}
```

## Alignment

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

## Text Wrapping

```dart
// Respects both "wrap" (bool) and "maxLines" (int) JSON properties
int maxLines = resolver.resolveMaxLines(
  wrap: adaptiveMap['wrap'] as bool?,
  maxLines: adaptiveMap['maxLines'] as int?,
);
// wrap=false → always 1; wrap=true → maxLines ?? 1
```
