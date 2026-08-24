---
name: adaptive-cards-dart-flutter-fvm
description: >
  FVM rules for the Flutter-AdaptiveCards monorepo. Prefix every `flutter` and
  `dart` shell command with `fvm`. Use when the `dart-flutter` plugin's
  dart/flutter skills show bare commands, when installing or switching the
  pinned SDK, or before analyze, test, pub, or build_runner workflows.
---

# FVM — Pinned Flutter SDK

This monorepo pins Flutter/Dart with [fvm](https://fvm.app/). **Every** shell
command that invokes `flutter` or `dart` must use the `fvm` prefix.

For **which directory** to run a command from, see
**`adaptive-cards-monorepo-workspace`**. For **library test conventions**, see
**`adaptive-cards-testing`**.

---

## Command substitutions

When a plugin skill, doc, or tool shows a bare command, translate it. The
`dart-*`/`flutter-*` skills come from the `dart-flutter` plugin and live in the
plugin cache, not in this repo — there is nothing here to patch, so the
translation happens at the moment you run the command:

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
- `.github/workflows/*.yml` → every `flutter-version:` and `sdk:` pin, not just one file (see **`adaptive-cards-release-flutter-upgrade-sdk`** for the full bump checklist)

Check the pin without switching:

```bash
cat .fvmrc
```

---

## Tooling notes

- **MCP Dart tools** do not honor the pin. The `dart-flutter` plugin registers
  `dart-mcp-server` as a bare `dart mcp-server`, so it runs whichever SDK is
  first on `PATH`. Treat its output as advisory and run the authoritative
  command via `fvm` when the pinned version matters.
- **VS Code** should set `dart.flutterSdkPath` to `.fvm/versions/<version>`.

---

## Related skills

| Skill | Role |
| --- | --- |
| `adaptive-cards-monorepo-workspace` | Layout, working directories, dependencies |
| `adaptive-cards-testing` | `flutter_adaptive_cards_fs` test helpers and goldens |
| `adaptive-cards-release-flutter-upgrade-sdk` | Pubspec, CI, changelog steps after SDK bump |
