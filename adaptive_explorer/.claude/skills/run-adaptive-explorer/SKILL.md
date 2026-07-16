---
name: run-adaptive-explorer
description: Build, run, drive, and screenshot the adaptive_explorer macOS desktop app. Use when asked to start/launch/run adaptive_explorer, take a screenshot of it, confirm a change renders in the real app, or run its tests.
---

adaptive_explorer is a Flutter **desktop** app (macOS/Linux/Windows — no web,
no mobile: it uses `dart:io` file-watching and native file dialogs). The agent
path builds and launches the real macOS app and captures a PNG **from inside the
process**, driven by
[`.claude/skills/run-adaptive-explorer/drive.sh`](drive.sh) →
[`driver_main.dart`](driver_main.dart).

All paths below are relative to `adaptive_explorer/`. Every `flutter`/`dart`
command is prefixed with `fvm` (the repo pins its SDK — Flutter 3.44.0 — via
FVM; bare `flutter` may be the wrong version).

## Prerequisites

- **macOS with Xcode** — the macOS desktop build shells out to `xcodebuild`.
- **FVM** with the pinned SDK installed: `fvm install` (reads `../.fvmrc`).
- A macOS desktop device — confirm with `fvm flutter devices` (look for
  `macOS (desktop)`).

There is no Linux container path here: this is a native desktop GUI and the
driver was verified on macOS only.

## Setup

From the **repo root** (this is a pub workspace — one resolve covers every
package):

```bash
cd ..
fvm flutter pub get
cd adaptive_explorer
```

## Run (agent path) — build, launch, screenshot, quit

```bash
.claude/skills/run-adaptive-explorer/drive.sh
```

What it does, with no human input:

1. `fvm flutter run -d macos -t .claude/skills/run-adaptive-explorer/driver_main.dart`
   — launches the real app. `driver_main.dart` boots it with a card already
   loaded (via the app's `initialTemplateJson` test seam) so there is content
   to see without clicking a native file dialog.
2. After first paint the app rasterises itself (a `RepaintBoundary` → PNG) into
   its sandbox temp dir and prints `SCREENSHOT_WRITTEN: <path>`.
3. The script copies that PNG to `./adaptive_explorer_screenshot.png` and quits
   the app.

Pass a custom output path as the first argument:

```bash
.claude/skills/run-adaptive-explorer/drive.sh /tmp/ae.png
```

First macOS build takes ~2–4 min; incremental runs are ~30–60s. The trailing
`Terminated: 15` line is the script quitting the app — it is expected, exit code
is still 0.

**Verified result** — the PNG shows the "Adaptive Explorer" app bar (Open
Template / Open Data / Save), the preview pane, the Template/Data/Merged tabs,
and the injected card JSON in the editor.

## Run (human path)

Opens a real window and blocks until you press `q`:

```bash
fvm flutter run -d macos            # empty "Select a template to view" screen
```

Then use the **Open Template** / **Open Data** buttons to load JSON from disk;
the preview pane re-renders on file save (file-watching). Useless headless — it
just waits for a window nobody can see.

## Test

```bash
fvm flutter test
```

Verified: 24 tests pass (`template_manager_test.dart`, `widget_test.dart`).

## Gotchas

- **The macOS debug build is sandboxed** (`macos/Runner/DebugProfile.entitlements`).
  The app cannot write a PNG to the repo dir or `/tmp` — `writeAsBytes` there
  fails with `Operation not permitted`. `driver_main.dart` writes to
  `Directory.systemTemp` (inside its container, still readable by the
  unsandboxed shell) and prints the path; `drive.sh` copies it out.
- **`screencapture` does not work** from a sandboxed/headless shell — it needs
  Screen Recording permission and returns `could not create image from display`.
  That is why capture happens *inside* the app, not via the OS.
- **`flutter screenshot` is useless here** — it only produces PNGs for physical
  Android/iOS devices; for desktop it errors `VM Service URI cannot be provided
  for screenshot type device`.
- **No web target.** `fvm flutter run -d chrome` will not compile — the app
  imports `dart:io` (file watcher). Desktop only.
- **The injected card fills the editor, not the preview.** The
  `initialTemplateJson` seam sets the editor tabs but the merge pipeline that
  feeds the preview only runs when a file is loaded from disk, so the screenshot
  shows `No preview available` in the preview pane. That is a limitation of the
  seam, not a bug in your change.

## Troubleshooting

- `Target file ".claude/…/driver_main.dart" not found` → you are not in
  `adaptive_explorer/`. `cd` there first (the target path is relative).
- `flutter run exited early` in the drive log → run
  `fvm flutter run -d macos -t .claude/skills/run-adaptive-explorer/driver_main.dart`
  directly to see the real compile error.
