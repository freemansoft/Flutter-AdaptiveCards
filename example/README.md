# AdaptiveCards example application example

This should demonstrate all the cards, local and remote sources for AdaptiveCards

## Getting Started

For help getting started with Flutter, view our online
[documentation](https://flutter.io/).


## Usage
These instructions assume you are exercising the web and run in mobile device mode to ignore CORS

### the demo

The actual demo

```
cd into this, example, directory
flutter run -d chrome --web-renderer html
```

### registry.dart

```
cd into this, example, directory
flutter run -t lib/registry.dart -d chrome --web-renderer html
```


### lab.dart
Displays an adaptive card. Lets you specify the URL or relative file location as a command line argument.  Intended as a debugging jig

This snippet assumes you want to test the adaptive card activity_update located in the example's lib directory. You could do a
```
cd example
flutter run  --dart-define=url=lib/activity_update lib/lab.dart -d chrome --web-renderer html
```

# Open Items

* `LabAdaptiveCard` doesn't have a _show the JSON_ function
* `GenericListPage` doesn't support enable/disable markdown. Fixing this could get rid of more of the sample page drivers