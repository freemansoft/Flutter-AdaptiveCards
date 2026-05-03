# Flutter Adaptive Cards

This project is a Flutter implementation of the Adaptive Cards specification. The Adaptive Cards project was originally developed by Microsoft and is now an open source project. You can find more information about Adaptive Cards at <https://adaptivecards.io/>. This particular implementation is a fork of the original project that was created to add support for Flutter. This project is not affiliated with Microsoft. The project was originally created by Neohelden.

## About Adaptive Cards

Adaptive Cards is a way of implementing Server Driven UI (SDUI) using a JSON based schema to deliver user interfaces specifications across platforms.

1. See the [Getting Started](/packages/flutter_adaptive_cards_fs/README.md) page for more information about this library.

## GitHub notes

The default branch has been renamed from the original repository. `master` is now named `main`

If you have a local clone, you can update it by running the following commands.

```bash
git branch -m master main
git fetch origin
git branch -u origin/main main
git remote set-head origin -a
```

## This project: Packages and tools

1. Tools
   1. You can view demonstrations of this implementation by running the [Widgetbook](widgetbook)
   1. There is a editor / preview tool at [packages/flutter_adaptive_cards_editor](/packages/flutter_adaptive_cards_editor/README.md)
1. Libraries
   1. The Adaptive Card library is in [packages/flutter_adaptive_cards_fs](/packages/flutter_adaptive_cards_fs/README.md)
   1. The Adaptive Card library CHANGELOG is in [packages/flutter_adaptive_cards_fs/CHANGELOG.md](/packages/flutter_adaptive_cards_fs/CHANGELOG.md)
1. Adaptive Card Charting is an extension that adds charting capabilities and is implemented in its own package so that its third party dependencies are isolated from the core library. [packages/flutter_adaptive_cards_charts](/packages/flutter_adaptive_cards_charts/README.md)
   1. The Adaptive Card Charting library CHANGELOG is in [packages/flutter_adaptive_cards_charts/CHANGELOG.md](/packages/flutter_adaptive_cards_charts/CHANGELOG.md)
1. The Adaptive Card Template library supports merging json data into an Adaptive Card template. It is implemented in its own package [packages/flutter_adaptive_cards_template](/packages/flutter_adaptive_cards_template/README.md)
   1. The Adaptive Card Template library CHANGELOG is in [packages/flutter_adaptive_cards_template/CHANGELOG.md](/packages/flutter_adaptive_cards_template/CHANGELOG.md)
   1. [Adaptive Cards Template specification](https://learn.microsoft.com/en-us/adaptive-cards/authoring-cards/card-templates)

1. azure bot service expressions are not currently supported.
   1. [Adaptive Expressions specification](https://learn.microsoft.com/en-us/azure/bot-service/adaptive-expressions/adaptive-expressions-prebuilt-functions?view=azure-bot-service-4.0)

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

### AGENTS.md

This project uses the [AGENTS.md](AGENTS.md) file to provide instructions to LLM agents, Antigravity, Cursor, and others. The contents came from the Flutter team's recommendation <https://docs.flutter.dev/ai/ai-rules>. This is the shorter 10K character version because of Antigravity's rule file character limit of 12,000 [antigravity user-rules](https://docs.antigravity.ai/user-rules#agents.md).

Changes from the verson created by the Flutter team:

- Linting rules changed from default to use VGV linter
- Use `riverpod` instead of `provider`
- Added **Semantic Label Keys** rule
- Added internationalizaiton and localization rules

### Skills

`.agents/skills/` contains the skills used by LLM agents.

The Flutter team's [skills](https://github.com/flutter/skills)

- flutter-add-integration-tests
- flutter-add-widget-preview
- flutter-add-widget-tests
- flutter-apply-architecture-best-practices
- flutter-build-responsive-layout
- flutter-fix-layout-issues
- flutter-implement-json-serialization
- flutter-setup-declarative-routing
- flutter-setup-localization
- flutter-use-http-package

The dart-lang [skills](https://github.com/dart-lang/skills)

- dart-add-unit-test
- dart-build-cli-app
- dart-collect-coverage
- dart-fix-runtime-errors
- dart-fix-static-analysis-errors
- dart-generate-test-mocks
- dart-migrate-to-checks-package
- dart-resolve-package-conflicts
- dart-run-static-analysis
- dart-use-pattern-matching

The following skills were created for this project using Antigravity LLM prompts

- adaptive-cards-monorepo-workspace
- adaptive-cards-element-registry
- adaptive-cards-flutter-standard-practices
- adaptive-cards-hostconfig-theme
- adaptive-cards-spec-compliance
- adaptive-cards-templating
- adaptive-cards-testing
- code-revew
- release-engineer

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
