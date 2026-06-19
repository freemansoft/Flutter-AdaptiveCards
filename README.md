# Flutter Adaptive Cards

This project is a Flutter implementation of the Adaptive Cards specification. The Adaptive Cards project was originally developed by Microsoft and is now an open source project. You can find more information about Adaptive Cards at <https://adaptivecards.io/>. This particular implementation is a fork of the original project that was created to add support for Flutter. This project is not affiliated with Microsoft. The project was originally created by Neohelden.

## About Adaptive Cards

Adaptive Cards is a way of implementing Server Driven UI (SDUI) using a JSON based schema to deliver user interfaces specifications across platforms.

1. See the [AdaptiveCards Getting Started](/packages/flutter_adaptive_cards_fs/README.md) page for more information about the core AdaptiveCards library.
2. See the [AdaptiveTemplating Getting Started](/packages/flutter_adaptive_template_fs/) for more info about the templating library that can sit in front of adaptive cards.

## GitHub notes

The default branch has been renamed from the original repository. `master` is now named `main`

If you have a local clone, you can update it by running the following commands.

```bash
git branch -m master main
git fetch origin
git branch -u origin/main main
git remote set-head origin -a
```

## This project: Packages

1. Libraries
   1. The Adaptive Card library is in [packages/flutter_adaptive_cards_fs](/packages/flutter_adaptive_cards_fs/README.md)
   1. The Adaptive Card library CHANGELOG is in [packages/flutter_adaptive_cards_fs/CHANGELOG.md](/packages/flutter_adaptive_cards_fs/CHANGELOG.md)
1. The Adaptive Card Host library is an optional backend invoke bridge (PlainJson and Teams-shaped request/response adapters, HTTP client, and `AdaptiveCardBackendHandlers` wiring). [packages/flutter_adaptive_cards_host_fs](/packages/flutter_adaptive_cards_host_fs/README.md)
   1. The Adaptive Card Host library CHANGELOG is in [packages/flutter_adaptive_cards_host_fs/CHANGELOG.md](/packages/flutter_adaptive_cards_host_fs/CHANGELOG.md)
1. Adaptive Card Charting is an extension that adds charting capabilities and is implemented in its own package so that its third party dependencies are isolated from the core library. [packages/flutter_adaptive_charts_fs](/packages/flutter_adaptive_charts_fs/README.md)
   1. The Adaptive Card Charting library CHANGELOG is in [packages/flutter_adaptive_charts_fs/CHANGELOG.md](/packages/flutter_adaptive_charts_fs/CHANGELOG.md)
1. The Adaptive Card Template library supports merging json data into an Adaptive Card template. It is implemented in its own package [packages/flutter_adaptive_template_fs](/packages/flutter_adaptive_template_fs/README.md)
   1. The Adaptive Card Template library CHANGELOG is in [packages/flutter_adaptive_template_fs/CHANGELOG.md](/packages/flutter_adaptive_template_fs/CHANGELOG.md)
   1. [Adaptive Cards Template specification](https://learn.microsoft.com/en-us/adaptive-cards/authoring-cards/card-templates)

1. azure bot service expressions are not currently supported.
   1. [Adaptive Expressions specification](https://learn.microsoft.com/en-us/azure/bot-service/adaptive-expressions/adaptive-expressions-prebuilt-functions?view=azure-bot-service-4.0)

## Widgetbook

The [widgetbook](widgetbook/) app is a **component gallery** for this project. It renders Adaptive Card JSON samples grouped by element and action type so you can browse layouts, inputs, actions, v1.6 extensions, and chart samples without writing a host app.

### What you can do widgetbook

- Browse use cases in the Widgetbook sidebar (TextBlock, inputs, actions, tables, charts, and more).
- Switch **light / dark** themes and viewport sizes from the Widgetbook toolbar.
- Inspect rendered cards from JSON under `widgetbook/lib/samples/` (each use case points at a sample file).
- Try **interactive host demos** that go beyond static JSON: **TextBlock → Text overlay** (knob-driven `setText`) and **Input.ChoiceSet → dependent country/city** (`valueChangedAction` reset + host `onChange` / `applyUpdates`) — see [form-inputs.md](docs/form-inputs.md#dependent-choiceset-country--city).

### Run Widgetbook from the repo root

```bash
cd widgetbook
fvm flutter pub get
fvm flutter run
```

Pick a desktop, web, or mobile device when prompted. On macOS, enable outgoing network connections in Runner signing if samples load remote images.

### After adding or renaming use cases

Use cases are declared in `widgetbook/lib/adaptive_cards_use_cases.dart`. Regenerate the Widgetbook directory tree, then restart the app:

```bash
cd widgetbook
fvm dart run build_runner build
fvm flutter run
```

### Adding new sample JSON

1. Place files under `widgetbook/lib/samples/` (mirror the existing folder layout).
2. Register the folder in `widgetbook/pubspec.yaml` under `flutter: assets:` if you create a new directory.
3. Add a `@widgetbook.UseCase` in `adaptive_cards_use_cases.dart` and run `build_runner` as above.

More detail: [widgetbook/README.md](widgetbook/README.md).

## adaptive_explorer

The [adaptive_explorer](adaptive_explorer/) app is a **desktop design studio** for authoring and previewing Adaptive Cards. It combines a live preview with JSON editors for template, data, and merged output—useful when you are editing card JSON in an external editor or testing templating.

### What you can do adaptive explorer

- **Open Template** — load an Adaptive Card template or fully resolved card JSON.
- **Open Data** (optional) — load a data file; the app merges template + data with `flutter_adaptive_template_fs` and previews the result.
- Edit template, data, or merged JSON in tabs (`json_editor_flutter`) and save changes.
- Watch the filesystem: when the open template or data file changes on disk, the preview refreshes automatically.
- Resize the split between preview and editor with the divider (preview above editor in portrait, side-by-side in landscape).

### Supported platforms

macOS, Windows, and Linux (desktop only).

### Run adaptive explorer from the repo root

```bash
cd adaptive_explorer
fvm flutter pub get
fvm flutter run
```

On macOS, the app uses `file_picker` and needs appropriate signing and entitlements for file access and network images (see [adaptive_explorer/README.md](adaptive_explorer/README.md#macos-specifics)).

### Typical workflow

1. Start the app.
2. Click **Open Template** and choose a `.json` file (template or resolved card).
3. Optionally click **Open Data** and choose a companion data file.
4. Use the Template / Data / Merged tabs to edit; the preview updates as you work or when files change externally.

More detail: [adaptive_explorer/README.md](adaptive_explorer/README.md).

## Platform Support

| Platform | Status | Notes                       |
| -------- | ------ | --------------------------- |
| Android  | ✅     |                             |
| iOS      | ✅     |                             |
| Web      | ✅     |                             |
| Linux    | ✅     | Only tested on build agents |
| macOS    | ✅     |                             |
| Windows  | ✅     | Video Player not supported  |

## Project Configuration

- Flutter versions are managed using fvm.
- This repository is managed using flutter workspaces via the `pubspec.yaml`

## Defects

Many!

- See [Defects](/packages/flutter_adaptive_cards_fs/README.md#defects)
- [Microsoft learning authoring cards text features](https://learn.microsoft.com/en-us/adaptive-cards/authoring-cards/text-features) may not all be implemented

## LLM Agent Support

This repo is configured for Claude Code, Antigravity, CoPilot and ~~Cursor~~, and other coding agents. Full setup, install commands, and update procedures are in **[docs/AI-Agent-Support.md](docs/AI-Agent-Support.md)**.

### Always-on rules — [AGENTS.md](AGENTS.md)

Always-on project guardrails (FVM, monorepo hygiene, Very Good Analysis, Riverpod document overlays, semantic labels, localization). Derived from the [Flutter team AI rules](https://docs.flutter.dev/ai/ai-rules), trimmed for Antigravity’s ~12K character limit.

### Task playbooks — [`.agents/skills/`](.agents/skills/)

Modular skills loaded when a task matches. Vendored upstream skills are tracked in [`skills-lock.json`](skills-lock.json).

> **Claude Code:** Opening this workspace in VS Code or Cursor automatically links `.agents/skills/` into `.claude/skills/` via a `folderOpen` task in [`.vscode/tasks.json`](.vscode/tasks.json). You will be prompted to _Allow_ the task once; after that it runs silently on every workspace open. To run it manually: `sh scripts/setup-claude.sh` (Mac/Linux) or `pwsh scripts/setup-claude.ps1` (Windows).
>
> Only built in skills show up when typing `/` in the Claude Code prompt. Superpowers and other customized skills do not show up in the `/` list in the VSCode plugin but do in a terminal command line. Claude itself says that the list shouldn't work but it did this morning in my terminal window

| Source           | Repository                                              | Count |
| ---------------- | ------------------------------------------------------- | ----- |
| Dart team        | [dart-lang/skills](https://github.com/dart-lang/skills) | 9     |
| Flutter team     | [flutter/skills](https://github.com/flutter/skills)     | 10    |
| Superpowers      | [obra/superpowers](https://github.com/obra/superpowers) | 14    |
| Project-specific | (authored in-repo)                                      | 11    |

**Project-specific skills:** `adaptive-cards-dart-flutter-fvm`, `adaptive-cards-monorepo-workspace`, `adaptive-cards-element-registry`, `adaptive-cards-flutter-standard-practices`, `adaptive-cards-hostconfig-theme`, `adaptive-cards-spec-compliance`, `adaptive-cards-templating`, `adaptive-cards-testing`, `code-review`, `release-engineer`, `release-flutter-upgrade-sdk`.

**Superpowers highlights:** `brainstorming`, `writing-plans`, `test-driven-development`, `systematic-debugging`, `subagent-driven-development`, and related collaboration workflows.

### Quick install (from repo root)

```bash
npx skills add dart-lang/skills --skill '*' --agent universal --yes
npx skills add flutter/skills --skill '*' --agent universal --yes
npx skills add obra/superpowers --skill '*' --agent universal --yes
```

Update vendored skills: `npx skills update`. For user-level Superpowers and the optional `/add-plugin superpowers` hook, see [docs/AI-Agent-Support.md](docs/AI-Agent-Support.md).

## More about adaptive cards and available SDKs

- [Adaptive Cards learning and specification site](https://learn.microsoft.com/en-us/adaptive-cards/)
- [Partners](https://learn.microsoft.com/en-us/adaptive-cards/resources/partners) using adaptive cards
- [Adaptive Cards for Android](https://learn.microsoft.com/en-us/adaptive-cards/sdk/rendering-cards/android/getting-started) is available as a [maven artifact](https://search.maven.org/artifact/io.adaptivecards/adaptivecards-android)
- [Adaptive Cards for ios is available as a pod](https://learn.microsoft.com/en-us/adaptive-cards/sdk/rendering-cards/ios/getting-started)
- [Adaptive Cards for javascript](https://learn.microsoft.com/en-us/adaptive-cards/sdk/rendering-cards/javascript/getting-started) is available via npm
- [Adaptive Cards for Windows WPF](https://learn.microsoft.com/en-us/adaptive-cards/sdk/rendering-cards/net-wpf/getting-started)
- [Adaptives Cards for Image](https://learn.microsoft.com/en-us/adaptive-cards/sdk/rendering-cards/net-image/getting-started) renders into a png
- [Adaptive Cards for Windows UWP](https://learn.microsoft.com/en-us/adaptive-cards/sdk/rendering-cards/uwp/getting-started)
- A community supported [Adaptive Cards for ReactNative](https://learn.microsoft.com/en-us/adaptive-cards/sdk/rendering-cards/react-native/getting-started)

There is also

- A [React Native designer SDK](https://learn.microsoft.com/en-us/adaptive-cards/sdk/designer)
- A [Javascript Templating SDK](https://learn.microsoft.com/en-us/adaptive-cards/templating/sdk) that can be used as a designer
