---
name: dart-monorepo-workspace
description: >
  Workspace layout, fvm usage, correct working directories for commands,
  and inter-package dependency relationships for the Flutter-AdaptiveCards
  monorepo. Use this whenever running flutter/dart commands or navigating
  the project structure.
---

# Dart Monorepo Workspace Skill

## Repository Layout

```
Flutter-AdaptiveCards/           ← workspace root (pubspec.yaml declares workspace)
├── pubspec.yaml                 ← workspace manifest ONLY — no real package here
├── .fvmrc                       ← pins Flutter SDK version (fvm)
├── packages/
│   ├── flutter_adaptive_cards_fs/    ← MAIN LIBRARY (published to pub.dev)
│   ├── flutter_adaptive_charts_fs/        ← charting extension package
│   └── flutter_adaptive_template_fs/      ← AdaptiveCard template merging package
├── adaptive_explorer/           ← desktop editor/preview app (not published)
└── widgetbook/                  ← widgetbook demo app (not published)
```

### `pubspec.yaml` Workspace Declaration

```yaml
name: _
publish_to: none
environment:
  sdk: ^3.10.4
workspace:
  - packages/flutter_adaptive_cards_fs
  - packages/flutter_adaptive_charts_fs
  - packages/flutter_adaptive_template_fs
  - widgetbook
  - adaptive_explorer
```

The root `pubspec.yaml` is **not a real package**. It exists solely to declare
the workspace and lock shared transitive dependencies in `pubspec.lock`.

---

## Flutter Version Management (fvm)

This project pins its Flutter SDK version with [fvm](https://fvm.app/).

```bash
# Use the pinned Flutter version for any command:
fvm flutter ...    # instead of plain `flutter`
fvm dart ...       # instead of plain `dart`

# Check which version is pinned:
cat .fvmrc

# Install the pinned version if it's missing:
fvm install
```

> **Important:** Always use `fvm flutter` / `fvm dart` to ensure the correct
> SDK version. Antigravity MCP tools (`mcp_dart-mcp-server_*`) use the system
> Flutter, so prefer shell commands via `fvm` when SDK version matters.

---

## Running Commands in the Correct Directory

Each package is an independent Flutter/Dart project. Run commands **from the
specific package directory**, not the workspace root.

| Task                      | Directory                            | Command                     |
| ------------------------- | ------------------------------------ | --------------------------- |
| Run main library tests    | `packages/flutter_adaptive_cards_fs` | `fvm flutter test`          |
| Add a dep to main library | `packages/flutter_adaptive_cards_fs` | `fvm flutter pub add <pkg>` |
| Run the explorer app      | `adaptive_explorer`                  | `fvm flutter run`           |
| Run the widgetbook app    | `widgetbook`                         | `fvm flutter run`           |
| Get all deps (workspace)  | Repo root                            | `fvm flutter pub get`       |
| Analyze all packages      | Repo root                            | `fvm flutter analyze`       |
| Format all code           | Repo root                            | `fvm dart format .`         |

### ✅ Correct — from package directory:

```bash
cd packages/flutter_adaptive_cards_fs
fvm flutter test test/basic_test.dart
```

### ❌ Wrong — from repo root:

```bash
fvm flutter test packages/flutter_adaptive_cards_fs/test/basic_test.dart
# This may fail because asset resolution and test config depend on CWD
```

---

## Inter-Package Dependencies

The `adaptive_explorer` and `widgetbook` apps depend on the library packages
using **path dependencies** (resolved automatically by the workspace):

```yaml
# widgetbook/pubspec.yaml excerpt
dependencies:
  flutter_adaptive_cards_fs:
    path: ../packages/flutter_adaptive_cards_fs
  flutter_adaptive_charts_fs:
    path: ../packages/flutter_adaptive_charts_fs
  flutter_adaptive_template_fs:
    path: ../packages/flutter_adaptive_template_fs
```

Changes to a library package are **immediately reflected** in the apps without
requiring a publish step — just hot reload or restart.

### Dependency Graph

```
adaptive_explorer  ──► flutter_adaptive_cards_fs
widgetbook         ──► flutter_adaptive_cards_fs
                   ──► flutter_adaptive_charts_fs
                   ──► flutter_adaptive_template_fs
flutter_adaptive_charts_fs   ──► flutter_adaptive_cards_fs
```

---

## Package Purposes

### `packages/flutter_adaptive_cards_fs` — Core Library

- **Published to pub.dev**
- Parses and renders Adaptive Cards JSON as Flutter widgets.
- Entry points:
  - `lib/flutter_adaptive_cards_fs.dart` — public API (import this in consuming apps)
  - `lib/flutter_adaptive_cards_extend.dart` — extension API (import when creating custom elements)
- Contains: element widgets, containers, inputs, actions, HostConfig, registry.

### `packages/flutter_adaptive_charts_fs` — Charts Extension

- **Published to pub.dev**
- Adds charting element types (isolates heavy chart dependencies).
- Registered via the extension API into a `CardTypeRegistry`.

### `packages/flutter_adaptive_template_fs` — Template Package

- **Published to pub.dev**
- Implements [AdaptiveCards template spec](https://learn.microsoft.com/en-us/adaptive-cards/authoring-cards/card-templates).
- Merges JSON data into an Adaptive Card template before rendering.

### `adaptive_explorer` — Desktop Editor/Preview App

- **Not published**
- macOS/Linux/Windows desktop app for editing and previewing Adaptive Card JSON.
- Uses `file_watcher_service.dart` to watch the JSON file on disk and live-reload
  the preview pane automatically.

### `widgetbook` — Component Demo App

- **Not published**
- Uses [widgetbook.io](https://widgetbook.io) to catalog all card element types.
- Use cases defined in `lib/adaptive_cards_use_cases.dart`.
- Generated file: `lib/main.directories.g.dart` — re-generate with:
  ```bash
  cd widgetbook
  fvm dart run build_runner build
  ```

---

## Analysis and Linting

Each package has its own `analysis_options.yaml`. The project uses
`very_good_analysis` as the base linting ruleset:

```yaml
include: package:very_good_analysis/analysis_options.yaml
```

Run analysis from the root to cover all packages at once:

```bash
fvm flutter analyze
```

---

## Changelog Updates

Whenever you make changes to one of the published packages (e.g., `flutter_adaptive_cards_fs`, `flutter_adaptive_charts_fs`, `flutter_adaptive_template_fs`):

1. **Always** append your changes to the corresponding `CHANGELOG.md` file in that package's directory.
2. If introducing new features or bug fixes, you should add an `## Unreleased` section to the `CHANGELOG.md` to document the changes properly.

---

## Pub Commands Reference

```bash
# Add a runtime dependency to main library
cd packages/flutter_adaptive_cards_fs
fvm flutter pub add some_package

# Add a dev dependency
fvm flutter pub add dev:some_dev_package

# Remove a dependency
fvm dart pub remove some_package

# Check outdated dependencies across all packages
# (run from each package directory)
fvm flutter pub outdated
```
