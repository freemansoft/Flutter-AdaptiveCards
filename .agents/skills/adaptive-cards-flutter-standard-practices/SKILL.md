---
name: flutter-standard-practices
description: >
  Standard patterns and best practices for Flutter development in the FlutterAdaptiveCards project.
  Covers Theming (Material 3) and JSON Serialization using code-generation.
  Load this skill when performing detailed UI or infrastructure work.
---

# Flutter Standard Practices

Use these guidelines to maintain a consistent high-quality UI and infrastructure across the monorepo.

---

## 1. Visual Design & Theming (Material 3)

- **Visual Design:** Build beautiful and intuitive user interfaces that follow modern design guidelines.
- **Typography:** Stress and emphasize font sizes to ease understanding, e.g., hero text, section headlines.
- **Background:** Apply subtle noise texture to the main background to add a premium, tactile feel.
- **Shadows:** Multi-layered drop shadows create a strong sense of depth; cards have a soft, deep shadow to look "lifted."
- **Icons:** Incorporate icons to enhance the user’s understanding and the logical navigation of the app.
- **Interactive Elements:** Buttons, checkboxes, sliders, lists, charts, graphs, and other interactive elements have a shadow with elegant use of color to create a "glow" effect.
- **Centralized Theme:** Define a centralized `ThemeData` object to ensure a consistent application-wide style.
- **Light and Dark Themes:** Implement support for both light and dark themes using `theme` and `darkTheme`.
- **Color Scheme Generation:** Generate harmonious color palettes from a single color using `ColorScheme.fromSeed`.

```dart
final ThemeData lightTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.deepPurple,
    brightness: Brightness.light,
  ),
  textTheme: GoogleFonts.outfitTextTheme(),
);
```

---

## 2. Data Handling & Serialization

> [!IMPORTANT]
> This project uses **code-generation** (`json_serializable` + `json_annotation`) for JSON serialization.
> Do **not** use the manual `dart:convert` approach shown in the `flutter-implement-json-serialization`
> skill — that skill is a generic Flutter reference and conflicts with the pattern used here.

- **JSON:** Use `json_serializable` and `json_annotation` (never manual `fromJson`/`toJson` maps).
- **Naming:** Use `fieldRename: FieldRename.snake` so JSON `snake_case` keys map to Dart `camelCase` fields automatically.
- **Code-gen:** Run `fvm flutter pub run build_runner build --delete-conflicting-outputs` to regenerate after any model change.
- **`toJson` opt-in:** Add `includeIfNull: false` to omit null fields from serialized output.

```dart
import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class User {
  const User({required this.firstName, required this.lastName});

  final String firstName;
  final String lastName;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
}
```
