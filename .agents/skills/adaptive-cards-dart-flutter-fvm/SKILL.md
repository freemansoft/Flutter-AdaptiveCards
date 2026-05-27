---
name: adaptive-cards-dart-flutter-fvm
description: >
  FVM rules for the Flutter-AdaptiveCards monorepo. Prefix every `flutter` and
  `dart` shell command with `fvm`. Use when vendored dart/flutter skills show
  bare commands, when installing or switching the pinned SDK, or before
  analyze, test, pub, or build_runner workflows.
---

# FVM — Pinned Flutter SDK

This monorepo pins Flutter/Dart with [fvm](https://fvm.app/). **Every** shell
command that invokes `flutter` or `dart` must use the `fvm` prefix.

For **which directory** to run a command from, see
**`adaptive-cards-monorepo-workspace`**. For **library test conventions**, see
**`adaptive-cards-testing`**.

---

## Command substitutions

When a vendored skill, doc, or tool shows a bare command, translate it:

| Shown | Run in this repo |
| --- | --- |
| `flutter …` | `fvm flutter …` |
| `dart …` | `fvm dart …` |
| `dart analyze` | `fvm flutter analyze` (repo root) |
| `dart fix --apply` | `fvm dart fix --apply` (package directory) |
| `dart test` (Flutter packages) | `fvm flutter test` (package directory) |
| `dart run build_runner build` | `fvm dart run build_runner build` |
| `flutter pub get` | `fvm flutter pub get` |
| `flutter pub publish` | `fvm flutter pub publish` |

---

## Install or switch SDK version

Run from the **repository root**:

```bash
fvm install <flutter-version>   # e.g. 3.44.0 — skip if already installed
fvm use <flutter-version>
fvm flutter --version
```

Confirm these files agree on the version:

- `.fvm/fvm_config.json`
- `.fvmrc`
- `.github/workflows/test.yml` → `flutter-version:` (see **`release-flutter-upgrade-sdk`** for the full bump checklist)

Check the pin without switching:

```bash
cat .fvmrc
```

---

## Tooling notes

- **MCP Dart tools** may use the system Flutter, not the fvm-pinned SDK. Prefer
  shell commands via `fvm` when the pinned version matters.
- **VS Code** should set `dart.flutterSdkPath` to `.fvm/versions/<version>`.

---

## Related skills

| Skill | Role |
| --- | --- |
| `adaptive-cards-monorepo-workspace` | Layout, working directories, dependencies |
| `adaptive-cards-testing` | `flutter_adaptive_cards_fs` test helpers and goldens |
| `release-flutter-upgrade-sdk` | Pubspec, CI, changelog steps after SDK bump |
