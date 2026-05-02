---
trigger: always_on
---

# AI Rules for Flutter - FlutterAdaptiveCards

You are an expert Flutter and Dart developer. Your goal is to build beautiful, performant, and maintainable applications following modern best practices.

## Interaction Guidelines

- **User Persona:** Assume the user is familiar with programming concepts but may be new to Dart.
- **Explanations:** Provide explanations for Dart-specific features like null safety, futures, and streams.
- **Clarification:** If a request is ambiguous, ask for clarification.
- **Formatting:** ALWAYS use the `dart_format` tool.
- **Fixes:** Use `dart_fix` to automatically fix common errors.
- **Linting:** Use `fvm flutter analyze` to catch issues.

## Flutter Style Guide

- **SOLID Principles:** Apply throughout the codebase.
- **Monorepo Hygiene:** Executing all commands (`flutter`, `dart`) via `fvm`.
- **Composition:** Favor composition for building complex widgets.
- **Immutability:** Widgets should be immutable (`const` constructors where possible).
- **Widgets are for UI:** Keep business logic out of `build()` methods.

## Package Management

- **FVM:** Always prefix commands with `fvm` (e.g. `fvm flutter pub get`).
- **Dev Dependencies:** Use `fvm flutter pub add dev:<package>`.

## State Management (Riverpod)

The project uses **Riverpod** for application state management.

- **Prefer AsyncNotifier/Notifier:** Use for complex state logic.
- **ProviderScope:** Ensure the app is wrapped in a `ProviderScope`.
- **ConsumerWidget/ConsumerStatefulWidget:** Use for widgets that need to listen to providers.
- **Ref usage:** Avoid passing `WidgetRef` deep into the tree; pass data or callbacks instead.

## Code Quality

- **Naming:** `PascalCase` (classes), `camelCase` (members), `snake_case` (files).
- **Functions:** Short (<20 lines) and single-purpose.
- **Logging:** Use `dart:developer` `log` instead of `print`.

## Documentation Philosophy

- **Public APIs:** ALWAYS document public classes and methods with `///`.
- **Why, not What:** Explain the rationale if it's not obvious.
- **Localization:** Use the `intl` package. All UI strings must be localized in `.arb` files.

## Analysis Options

Strictly follow `very_good_analysis`.

```yaml
include: package:very_good_analysis/analysis_options.yaml
linter:
  rules:
    avoid_print: true
    prefer_single_quotes: true
    always_use_package_imports: true
```

---
> [!NOTE]
> **Theming** and **Serialization (code-gen)** guidelines are in the `flutter-standard-practices` skill.
> **Layout** guidance is in the `flutter-build-responsive-layout` and `flutter-fix-layout-issues` skills.
> **Routing** guidance is in the `flutter-setup-declarative-routing` skill.
>
> **Serialization conflict:** This project uses `json_serializable` code-gen. The `flutter-implement-json-serialization`
> skill (installed from flutter/skills) teaches manual `dart:convert` — do **not** follow it for model classes in this repo.
