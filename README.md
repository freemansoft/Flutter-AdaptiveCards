# Flutter Adaptive Cards

This project is a Flutter implementation of the Adaptive Cards specification. The Adaptive Cards project was originally developed by Microsoft and is now an open source project. You can find more information about Adaptive Cards at <https://adaptivecards.io/>. This particular implementation is a fork of the original project that was created to add support for Flutter. This project is not affiliated with Microsoft. The project was originally created by Neohelden.

## About Adaptive Cards

Adaptive Cards is a way of implementing Server Driven UI (SDUI) using a JSON based schema to deliver user interfaces specifications across platforms.

1. See the [Getting Started](packages/flutter_adaptive_cards/README.md) page for more information about this library.

## The default branch has been renamed!

`master` is now named `main`

If you have a local clone, you can update it by running the following commands.

```
git branch -m master main
git fetch origin
git branch -u origin/main main
git remote set-head origin -a
```

## Getting Started

1. You can view demonstrations of this implementation by running the [Widgetbook](widgetbook)
1. The actual library is in [packages/flutter_adaptive_cards](packages/flutter_adaptive_cards/README.md)
   The changelog is in [packages/flutter_adaptive_cards/CHANGELOG.md](packages/flutter_adaptive_cards/CHANGELOG.md)
1. [Adaptive Expressions reference](https://learn.microsoft.com/en-us/azure/bot-service/adaptive-expressions/adaptive-expressions-prebuilt-functions?view=azure-bot-service-4.0)
1. [Adaptive Cards Template reference](https://learn.microsoft.com/en-us/adaptive-cards/authoring-cards/card-templates)

## Platform Support

| Platform | Status | Notes                       |
| -------- | ------ | --------------------------- |
| Android  | ✅     |                             |
| iOS      | ✅     |                             |
| Web      | ✅     |                             |
| Linux    | ✅     | Only tested on build agents |
| macOS    | ✅     |                             |
| Windows  | ✅     | Video Player not supported  |

## Configuration via HostConfig

HostConfig is a JSON object that contains configuration options for the Adaptive Card renderer. It is used to control the appearance and behavior of the Adaptive Card renderer. It is passed to the AdaptiveCard widget as a parameter. The HostConfig is optional and if not provided, the Fallback HostConfig will be used. In cases where a partial HostConfig is provided the Fallback subgraph will be used for the missing json objects. This means you can provide a partial HostConfig and only override the Entities you want to change. All of the primitive properties in a specific HostConfig Entity are required. Fallback is at the entitiy level.

## Defects

Many!

- styling not finished
- https://learn.microsoft.com/en-us/adaptive-cards/authoring-cards/text-features may not all be implemented
-
