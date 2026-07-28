---
name: adaptive-cards-flutter-standard-practices
description: >
  Use when writing or reviewing model (de)serialization or theming in this repo,
  or before adding a `fromJson`/`toJson`. The library packages diverge from two
  things generic Flutter skills assume: they hand-write serialization (no
  `json_serializable` / code-gen) and style elements from HostConfig (not
  app-level `ThemeData`/`GoogleFonts`). Read this when a generic skill or habit
  points you at `@JsonSerializable`, `build_runner` for models, or `ColorScheme`
  app theming inside `packages/`.
---

# Flutter Standard Practices (this repo)

Two conventions here differ from generic Flutter guidance. Applying the generic
pattern produces code that does not match the codebase — this skill records the
divergence so you follow the repo's actual approach.

---

## 1. Serialization — hand-written `fromJson`/`toJson`, **no code-gen**

The packages do **not** use `json_serializable`/`json_annotation`. There is no
`@JsonSerializable` annotation and no `.g.dart` model file anywhere under
`packages/` — every model is parsed and emitted by hand
(`flutter_adaptive_cards_fs` alone has ~39 hand-written `fromJson` factories).

Follow these conventions:

- **Manual factory + method.** `factory X.fromJson(Map<String, dynamic> json)`
  and `Map<String, dynamic> toJson()`. Do **not** add `json_serializable`,
  `json_annotation`, or a `build_runner` code-gen step for models.
- **Read Adaptive Cards keys verbatim.** Card JSON keys are the spec's
  **camelCase** names (`isVisible`, `backgroundImage`, `associatedInputs`). Read
  them as-is — never `FieldRename.snake`.
- **Null-safe reads with typed casts and defaults:**
  `json['title'] as String? ?? ''`, `json['value']?.toString() ?? ''`.
- **Immutable value types.** `@immutable`, `const` constructor, and value
  equality (`==` / `hashCode`).
- **Parse arrays with a small top-level helper** that guards bad entries rather
  than assuming the list is well-formed.

```dart
@immutable
class Choice {
  const Choice({required this.title, required this.value});

  /// Parses an Adaptive Cards `Input.Choice` object from card JSON.
  factory Choice.fromJson(Map<String, dynamic> json) {
    return Choice(
      title: json['title'] as String? ?? '',
      value: json['value']?.toString() ?? '',
    );
  }

  final String title;
  final String value;

  Map<String, dynamic> toJson() => {'title': title, 'value': value};
}

/// List helper: guards non-map entries instead of trusting the array.
List<Choice> choicesFromJsonList(Object? raw) {
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((e) => Choice.fromJson(Map<String, dynamic>.from(e)))
      .toList();
}
```

> The generic `flutter-implement-json-serialization` skill's manual
> `dart:convert` approach is **directionally correct** here — but follow the
> conventions above, and do **not** reach for `json_serializable`.

---

## 2. Theming — HostConfig-driven in packages, not app `ThemeData`

Element styling under `packages/` comes from Adaptive Cards **HostConfig**,
resolved through `ReferenceResolver` — not from a `MaterialApp` `ThemeData`,
`ColorScheme.fromSeed`, or `GoogleFonts`. Before changing colors, spacing, or
fonts in an element, use **`adaptive-cards-hostconfig-theme`**.

The sample apps are different: `widgetbook/` and `adaptive_explorer/` are
ordinary Flutter apps and legitimately set a `MaterialApp` theme
(`ThemeData.light()`/`dark()`, `ColorScheme.fromSeed`). That is **sample-app
scope only** — it is never how library elements pick up style.

---

## Related skills

| Skill | Role |
| --- | --- |
| `adaptive-cards-hostconfig-theme` | How elements resolve theme-aware color/font/spacing from HostConfig |
| `adaptive-cards-element-registry` | Implementing a new element (where `fromJson` lives) |
| `adaptive-cards-public-api-docs` | `///` docs for the public model/factory APIs |
