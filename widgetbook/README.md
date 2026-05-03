# widgetbook for Flutter Adaptive Cards

A trashy use of the [Widgetbook](https://widgetbook.io) library from [Widgetbook pub.dev](https://pub.dev/packages/widgetbook) to view various json adaptive card samples in the Flutter Adaptive Cards project. The goal is to use this to explore rendering adaptive cards in Flutter. This is mostly json file driven and there is no way to manipulate any of the properties of the adaptive cards to see how they render.

## Refresh the code generated after every change in the use cases. You must refresh and restart to see json file changes

```bash
dart run build_runner build -d
flutter run
```

## Adding a new category or directory of json samples

Remember to add any new directory in lib/samples to the asset list in `pubspec.yaml`

## mac OS changes

1. Outgoing connections had to be enabled in the Runner Signing & Capabilities
