---
name: run-widgetbook
description: Build, run, drive, and screenshot the widgetbook sample app. Use when asked to start/launch/run widgetbook, take a screenshot of it, preview Adaptive Card samples or chart/overlay demos, or run its tests.
---

widgetbook is the Flutter Adaptive Cards **sample/demo** app (a Widgetbook
catalog of card JSON samples, chart overlays, and host-callback demos). The
agent path builds and launches the real macOS app and captures a PNG **from
inside the process**, driven by
[`.claude/skills/run-widgetbook/drive.sh`](drive.sh) →
[`driver_main.dart`](driver_main.dart).

All paths below are relative to `widgetbook/`. Every `flutter`/`dart` command is
prefixed with `fvm` (the repo pins Flutter 3.44.0 via FVM; bare `flutter` may be
the wrong version).

## Prerequisites

- **macOS with Xcode** — the macOS desktop build shells out to `xcodebuild`.
- **FVM** with the pinned SDK installed: `fvm install` (reads `../.fvmrc`).
- A macOS desktop device — confirm with `fvm flutter devices` (look for
  `macOS (desktop)`).

widgetbook *does* also target web/mobile, but the driver here was verified on
macOS desktop (no `chromium-cli` is installed on this machine).

## Setup

From the **repo root** (this is a pub workspace — one resolve covers every
package):

```bash
cd ..
fvm flutter pub get
cd widgetbook
```

**Code generation.** widgetbook is code-generated: `main.dart` imports
`lib/main.directories.g.dart`, which indexes every `@widgetbook.UseCase`.
`drive.sh` runs this automatically when the file is missing; to do it by hand:

```bash
fvm dart run build_runner build --delete-conflicting-outputs
```

Regenerate + restart after adding/renaming a use case or sample folder.

## Run (agent path) — build, launch, screenshot, quit

```bash
.claude/skills/run-widgetbook/drive.sh
```

What it does, with no human input:

1. Generates `main.directories.g.dart` if absent.
2. `fvm flutter run -d macos -t .claude/skills/run-widgetbook/driver_main.dart`
   — launches the real `WidgetbookApp`.
3. After first paint the app rasterises itself (a `RepaintBoundary` → PNG) into
   its sandbox temp dir and prints `SCREENSHOT_WRITTEN: <path>`.
4. The script copies that PNG to `./widgetbook_screenshot.png` and quits the app.

Pass a custom output path as the first argument:

```bash
.claude/skills/run-widgetbook/drive.sh /tmp/wb.png
```

First macOS build takes a few minutes; incremental runs are ~30–60s. The
trailing `Terminated: 15` / `Lost connection to device` lines are the script
quitting the app — expected, exit code is still 0.

**Verified result** — the PNG shows the Widgetbook home ("Adaptive Cards for
Flutter" with the New / Legacy / This repository link cards) and the
Navigation / Addons / Knobs bar, in the dark default theme.

## Run (human path)

Opens a real window and blocks until you press `q`. To browse the catalog and
have it pick up JSON/use-case changes:

```bash
fvm dart run build_runner build --delete-conflicting-outputs
fvm flutter run -d macos
```

Useless headless — it just waits for a window nobody can see.

## Test

```bash
fvm flutter test
```

Verified: 1 placeholder test passes (`test/widget_test.dart`). widgetbook's real
coverage lives in the library packages under `../packages/`.

## Gotchas

- **The macOS debug build is sandboxed** (`macos/Runner/DebugProfile.entitlements`).
  The app cannot write a PNG to the repo dir or `/tmp` — it fails with
  `Operation not permitted`. `driver_main.dart` writes to `Directory.systemTemp`
  (inside its container, still readable by the unsandboxed shell) and prints the
  path; `drive.sh` copies it out.
- **`screencapture` does not work** from a sandboxed/headless shell (needs
  Screen Recording permission; returns `could not create image from display`).
  Capture happens *inside* the app instead.
- **`flutter screenshot` is useless here** — PNGs only for physical
  Android/iOS devices, not desktop.
- **Missing/stale `main.directories.g.dart`** → build fails with an import
  error on that file, or new use cases don't appear. Rerun `build_runner`.
- The captured layout is the **compact** Widgetbook shell (bottom Navigation /
  Addons / Knobs bar) because the boundary is rasterised at the window's logical
  size; the same app shows a wider master-detail layout in a maximized window.

## Troubleshooting

- `Target file ".claude/…/driver_main.dart" not found` → you are not in
  `widgetbook/`. `cd` there first (the target path is relative).
- `flutter run exited early` in the drive log → run
  `fvm flutter run -d macos -t .claude/skills/run-widgetbook/driver_main.dart`
  directly to see the real compile error.
