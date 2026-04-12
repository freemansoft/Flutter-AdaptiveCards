---
name: flutter-standard-practices
description: >
  Standard patterns and best practices for Flutter development in the FlutterAdaptiveCards project.
  Includes Layout, Theming, Routing, and Serialization guidelines.
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

## 2. Layout Best Practices

- **Expanded:** Use to make a child widget fill the remaining available space along the main axis.
- **Flexible:** Use when you want a widget to shrink to fit, but not necessarily grow. Don't combine `Flexible` and `Expanded` in the same `Row` or `Column`.
- **Wrap:** Use when you have a series of widgets that would overflow a `Row` or `Column`, and you want them to move to the next line.
- **SingleChildScrollView:** Use when your content is intrinsically larger than the viewport, but is a fixed size.
- **ListView / GridView:** For long lists or grids of content, always use a builder constructor (`.builder`).
- **FittedBox:** Use to scale or fit a single child widget within its parent.
- **LayoutBuilder:** Use for complex, responsive layouts to make decisions based on the available space.

---

## 3. Data Handling & Serialization

- **JSON:** Use `json_serializable` and `json_annotation`.
- **Naming:** Use `fieldRename: FieldRename.snake` for consistency.

```dart
@JsonSerializable(fieldRename: FieldRename.snake)
class User {
  final String firstName;
  final String lastName;
  User({required this.firstName, required this.lastName});
  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
```

---

## 4. Routing (GoRouter)

Use `go_router` for all navigation needs (deep linking, web). Ensure users are redirected to login when unauthorized.

```dart
final GoRouter _router = GoRouter(
  routes: <RouteBase>[
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
      routes: <RouteBase>[
        GoRoute(
          path: 'details/:id',
          builder: (context, state) {
            final String id = state.pathParameters['id']!;
            return DetailScreen(id: id);
          },
        ),
      ],
    ),
  ],
);
```
