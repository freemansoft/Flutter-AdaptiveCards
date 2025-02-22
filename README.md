# Adaptive Cards in Flutter

This is an Adaptive Card implementation for Flutter that has been been updated from the original by others. They did amazing work. No one appears to be doing PRs to bring it back to the original so I'm just listing the forking history below.

![Adaptive Cards](https://adaptivecards.io/content/bf-logo.png)

* [Adaptive Cards website](https://adaptivecards.io/)
* [Adaptive Cards Schema Docs](https://adaptivecards.io/explorer)
* [The main GitHub repo with samples](https://github.com/microsoft/AdaptiveCards)
  * [The v1.5 samples on the main GitHub repo](https://github.com/microsoft/AdaptiveCards/tree/main/samples/v1.5/Scenarios)
  * [Template samples. Templates are not supported in this library](https://github.com/microsoft/AdaptiveCards/tree/main/samples/Templates/Scenarios)
* [Description of Active Cards]( https://github.com/MicrosoftDocs/AdaptiveCards)
* [Another example repo containing samples/templates](https://github.com/pnp/AdaptiveCards-Templates)

Teams often create a flow management layer in front of the core business services. The cannonical flow would be

```mermaid
sequenceDiagram
    participant user as User
    participant browser as Client or Browser or Device
    participant flutter-app as Flutter App
    participant flow-services as Flow Services
    participant remote-site as Backend API

    user        ->> browser: User Action
    browser     ->> flutter-app: Submit Request
    activate flutter-app
    flutter-app ->> remote-site: API Call
    remote-site -->> flutter-app: Results
    flutter-app ->> flow-services: Activate Flow
    activate flow-services
    flow-services ->>  remote-site: Invoke API
    activate remote-site
    remote-site -->> flow-services: API Results
    deactivate remote-site
    flow-services ->>  flow-services: Generate Flow
    flow-services -->> flutter-app: Adaptive Card
    deactivate flow-services
    flutter-app ->>  flutter-app: Create Widget Tree from Adaptive Cards
    flutter-app ->> remote-site: API Call
    remote-site -->> flutter-app: Results
    flutter-app -->> browser: Device markup / Controls
    deactivate flutter-app
```

## Adaptive Card Color handling has changed

It used to be there were 3 background styles and 5 foreground styles plus light/dark.  Then Microsoft defined 5 background styles that align with the 5 foregound styles.  This library makes the assumption that the 'default' foreground color for a style should align with the background color for that style. This means we can map the Flutter `container` styles and `onContainer` styles to the Adaptive Card styles.  So if you pick a container style then you will automatically get the right foreground color for that style if you don't specify anything.

Adaptive Card Container ColorStyles now map to themed Flutter container styles.

```mermaid
flowchart
  subgraph ContainerStyles[Background Color from ContainerStyles]
  notset[ContainerStyle not specified] --> inherited[inherited from parent]
  default[ContainerStyle default] --> primaryContainer
  emphasis[ContainerStyle emphasis] --> secondaryContainer
  good[ContainerStyle good] --> tertiaryContainer
  attention[ContainerStyle attention] --> errorContainer
  warning[ContainerStyle waring] --> errorContainer
  end
```

The CardStyle foreground color comes from the containers when the foreground style is 'default'.
All other foreground styles are retrieved from the host_config.

```mermaid
flowchart
  subgraph ForegroundStyles[Foreground Color from Styles]
  notset[widget style not specified] --> inherit[Inherit from parent]
  default[widget style default] --> associatedContainer["onContainer that matches the current container bound by style above" ]
  emphasis[widget style emphasis] --> container["onContainer that matches the container bound by style above"]
  good[widget style good] --> container
  attention[widget style attention] --> container
  warning[widget style warning] --> container
  unrecognized --> <tbd>
  end
```

## Loading Data into fields outside of the AdaptiveCard JSON

You can create an AdaptiveCard stack with the AdaptiveCard json and also pass in a data map that will be passed across the AdaptiveCard widget Tree.
`initData` is demonstrated in the sample app on the `initData` button. `loadData` was in the sample app but was removed and needs to be re-added.

* `InitData` / `InitInput` can be used for late binding data into a widget tree
  * `initData` injected directly into a widget tree and visited across the tree in `InitInput`
  * `initInput(initData)` used to replace values in inputs. `initData` is a widget parameter.
  * `initInput` is called if initData exists on component
* `loadInput` used for choice selector lists only, at runtime, in choice set. bound by id

## Event Handlers

You can insert a `DefaultAdaptiveCardHandlers` in the Widget tree prior to loading the `AdaptiveCard`s.  Those handlers will be used for all actions.

Your program can pass it's own handlers to the `AdaptiveCard` constructors.  See the `NetworkPage` class in the example app.

## Example Execution

There is an expansive example program that demonstrates all Adaptive Cards. See [example README.md](example/README.md)

## Tests

The test use the standard flutter testing mechanism which uses the `FlutterTest` font or the `Ahem` font.

* The tests used to load the Roboto fonts to get an exact match but the line spacing can be off between platforms.
* I've updated the golden images (again) to use the default testing font.  The line spacing is subtly different so you have to pick a platform for the golden tests which means I've poluted the repo for no reason. <https://github.com/flutter/flutter/issues/2943>

1. Note that the test could upgrade to ebay's golden toolkit that renders fonts.  In that case we could bring back the Roboto fonts. Golden toolkit can show black bars instead of text if font isn't loaded <https://pub.dev/packages/golden_toolkit>

## Compatibility

Compatability changes should be captured in the Changelog section below

This codebase has been updated to support some of the null safety requred for 3.7.0+.  It works with the following version of flutter.

```powershell
PS C:\dev\flutter> flutter --version
Flutter 3.10.6 • channel stable • https://github.com/flutter/flutter.git
Framework • revision f468f3366c (4 days ago) • 2023-07-12 15:19:05 -0700
Engine • revision cdbeda788a
Tools • Dart 3.0.6 • DevTools 2.23.1
```

You can move to this version of flutter by:

```zsh
cd <flutter-install-directory>
Flutter channel stable
Flutter upgrade

```

Released Flutter / Dart bundling versions are located here: <https://docs.flutter.dev/release/archive?tab=windows>

## VS Code

This repo has been reformatted and updated using VS Code extensions.  The VS Code Flutter/Dart extension cleaned up some imports and mad other changes that have been comitted to the repository.

1. VSCode told me to enable `Developer Mode` in **Windows** settings in order to run the examples. Is that for the Windows app or the Web app?

### Plugins used during coding

* Flutter
* Dart
* dart-import
* markdownlint
* Markdown Preview Mermaid
* Intellicode
* GitHub Actions
* GitLens

## Widget Hierarchy with Flutter-AdaptiveCards

The Widgets marked with `(*)`are Flutter-AdaptiveCars specific including those build using the `Provider` framework.

```
Demo Adaptive Card*
├── Selection Area (copy/paste enable)
│   └── Padding
│       └── Column
│           └── AdaptiveCard(*)
│               └── RawAdaptiveCard(*)
│                   └── Provider<RawAdaptiveCardState>(*)
│                       └── InheritedReferenceResolver(*)
│                               └── Card
│                                   └── Column
│                                       ├── TextButton
│                                       ├── Divider
│                                       └── AdaptiveCardElement(*)
│                                           └── Provider<AdaptiveCardElement>(*)
│                                               └── Form
│                                                   └── Container
│                                                       └── Column
│                                                           ├── AdaptiveTextBlock(*)
│                                                           │   └── SeparatorElement
│                                                           │       └── Column
│                                                           │           └── ...
│                                                           └── AdaptiveColumnSet(*)
│                                                               └── SeparatorElement
│                                                                   └── Column
│                                                                       └── SizedBox
│                                                                           └── AdaptiveTapable(*)

```

Taken from the example App

## Open TODO items

TODO for the example programs moved to [example README](example/README.md)

* `initData` does not appear to be working on date fields.  The `initData` button in the sample program demonstrates this
* Currently uses `Provider` for inherited state.  Determine if this 3rd party dependency is a good idea given `Provider`` is essentially EOL or frozen.
* Add template and data json merge support - Adaptive Cards 1.3
* Find out if there is any regex validation tag or extension
* There is currently no way to unset a container style inside a child container. This means you can't get back to a card background color in a nested container if you set it somewhere in the widget tree betwen you and the card.
* Make a single purpose dart file for consumer imports with no code in it in place of `flutter_adaptive_cards.dart` or move the code in that file.
* Inject locale behavior in more places
* _Card Elements_ missing implementations and features
  * Add [`RichTextBlock`](https://adaptivecards.io/explorer/RichTextBlock.html)
  * Add [`TextRun`](https://adaptivecards.io/explorer/TextRun.html)
  * Note: [`MediaSource`](https://adaptivecards.io/explorer/MediaSource.html) currently implemented as a map in [`Media`](https://adaptivecards.io/explorer/Media.html)
  * [`Media`](https://adaptivecards.io/explorer/Media.html) `poster` attribute does not show poster, possibly with the latest media player update
* _Containers_ missing implementations and features
  * Add [`Table`](https://adaptivecards.io/explorer/Table.html) attributes
    * Column sizes, grid style show grid lines, etc
    * [`TableCell`](https://adaptivecards.io/explorer/TableCell.html) currently implemented in-line in [`Table`](https://adaptivecards.io/explorer/Table.html)
  * Note: [`Fact`](https://adaptivecards.io/explorer/Fact.html) currently implemented as a map in `FactSet`
* _Inputs_ missing implementations and features
  * None identified
  * Note: [`Input.Choice`](https://adaptivecards.io/explorer/Input.Choice.html) currently implemented as a map in [`ChoiceSet`](https://adaptivecards.io/explorer/Input.ChoiceSet.html)
* Actions_ missing implementations and features
  * Add [`Action.ToggleVisibility`](https://adaptivecards.io/explorer/Action.ToggleVisibility.html) - currently implemented as `no-op` along with its' associated [`TargetElement`](https://adaptivecards.io/explorer/TargetElement.html)
  * [`Action.Execute`](https://adaptivecards.io/explorer/Action.Execute.html) and [`Action.Submit`](https://adaptivecards.io/explorer/Action.Submit.html) are currently both mapped to `AdaptiveActionSubmit` in `action_set.dart`. Their behavior should possibly be different.
* _Tests_
  * findText for Text doesn't seem to be working so commented out in `basic_test.dart`
  * Font line spacing is subtly different between platforms.  You can see this if you use the "fade" view when looking at diffs on a golden png in the repo
  * Using default flutter fonts instead of roboto <https://github.com/flutter/flutter/issues/56383>
    * Could use golden toolkit but it will show black bars instead of text if font isn't loaded <https://pub.dev/packages/golden_toolkit>
  * `example\widget_test.dart` should never be working because we don't have any code that has an increment button and counters.  Probably should be either renamed again to not be picked up., deleted or disabled.

## ChangeLog

2023 09

* Removed hostconfig - some pieces still to be put together
  * 3 styles still to be fixed in the resolver

2023 07

* hostconfig
  * Removed containerStyles
  * hostconfig background colors are ignored in place of the container background colors
  * hostconfig foreground colors are ignored in place of container foreground colors when set to 'default'
* hostconfig colors are ARGB so an alpha channel is always needed - host_config files updated
* Remove `approximateDarkThemeColors` and brightness because people should use light and dark themes
* Remove `fontSizes` and `fontWeights` from host_config - use inherited themes
* Eliminate all hard coded Text sizes and colors to use inerited themes
* Updated to work with Flutter > 3.7 that implements null safety. Tested with Flutter 3.10
* added minimal `Table` implementation as a starting point
* migrated from `print()` to `developer.log()`
* Support both Material and Cupertino Date and Time pickers based on platform
* Test:
  * Flutter tests must end in `_test`.  Renamed `_tests` files to `_test`
  * Test upgrade to work with Flutter 3.10 and flutter_test ???
  * Added simple `Table` test
  * Migrated test off `Roboto` font to default testing font in an attempt to make more platform agnostic. line spacing was different on different platforms even using project bundled Roboto
  * Upgraded testing SDK

2023 06

* Updated where nulls were used by Flutter is now null safe.
* Picked a default with for text alignment that may be wrong or differ from the old default.
* Minor changes to use Material in one config file because VS Code warned about it
* used VS Code plugin `dart import` to organize imports
* Test:
  * Just did the dumb fix for mockito mocking with null safety.
  * Test images updated for windows
  * Image URLs updated to their new homes.  Some old sites were migrated or taken down
* android with Java 17
  * gradle upgrade from 5.6.2 to 7.4.2
  * upgraded kotlin version to 1.8.22
  * added `--add-opens=java.base/java.io=ALL-UNNAMED` to jvm args to run on Java 17 (Java 16+)

_________________________________________________________________________

# Repository History

Everything below this line is from the original README.md
The referenced GitHub repository has vanished.  Look at the forking train to figure out where the current repository was forked from or look here:

1. <https://github.com/freemansoft/Flutter-AdaptiveCards> Mine forked from
1. <https://github.com/lannes/Flutter-AdaptiveCards> forked from
1. <https://github.com/juansoilan/Flutter-AdaptiveCards> forked from the original
1. <https://github.com/rodydavis/Flutter-AdaptiveCards> the original but possibly from the no longer here repo
1. <https://github.com/neohelden/Flutter-AdaptiveCards>

_________________________________________________________________...

# Adaptive Cards for Flutter

## Installing

No releases have been created for 0.2.0 at this time. This is a placeholder for when the Git repo starts creating releases

Add this to your package's pubspec.yaml file:

```yml
dependencies:
  flutter_adaptive_cards: ^0.2.0
```

```dart
import 'package:flutter_adaptive_cards/flutter_adaptive_cards.dart';
```

## Using

Using Adaptive Cards in Flutter coudn't be simpler: All you need is the `AdaptiveCard` widget.

### :warning: Markdown support vs. ColumnSet content alignment

Due to [issue #171](https://github.com/flutter/flutter_markdown/issues/171) of the Flutter Markdown package, the flag `supportMarkdown` was introduced to all Adaptive Card contractors. The default value of this property is `true`, to stay compatible with older versions of this package, which didn't support content alignment in ColumnSets. If the value is set to `false` the content alignment in ColumnSets is working accordingly, but every TextBlock is displayed without Markdown rendering. As soon if the issue is resolved this flag will be removed.

### Loading an AdaptiveCard

There are several constructors which handle loading of the AC from different sources.
`AdaptiveCard.network` takes a url to download the payload and display it.
`AdaptiveCard.asset` takes an asset path to load the payload from the local data.
`AdaptiveCard.memory` takes a map (which can be obtained but decoding a string using the json class) and displays it.

### Example

```dart
AdaptiveCard.network(
  placeholder: Text("Loading, please wait"),
  url: "www.someUrlThatPoints.To/A.json",
  hostConfigPath: "assets/host_config.json",
  onSubmit: (map) {
    // Send to server or handle locally
  },
  onOpenUrl: (url) {
    // Open url using the browser or handle differently
  },
  // If this is set, a button will appear next to each adaptive card which when clicked shows the JSON payload.
  // NOTE: this flag only has impact in development mode, this attribute does change nothing for realease builds.
  // This is very useful for debugging purposes
  showDebugJson: true,
);
```

## Example App

We try to show every possible configuration parameter supported by the AdaptiveCards components in the example app of this repository. If we missed any, please feel free to open an issue.

## Running the tests

Test files must end in `_test` , `_test.dart` in order to be recognized by the test jig.

```sh
flutter test
```

to see the result of each test

```sh
flutter test -r expanded
```

and to update the golden files run

```sh
flutter test --update-goldens test/sample_golden_test.dart
```

This updates the golden files for the sample cards. Depending on your operating system you might have issues with the font rendering. For the CI / CD setup you need to generate the golden files using a Docker container:

```zsh
# run the following command in the root folder of this project
docker run -it -v `pwd`:/app cirrusci/flutter:dev bash

# and inside the container execute
cd /app
flutter test --update-goldens

# afterwards commit the freshly generated sample files (after checking them)
```

## Contributing

Please read [CONTRIBUTING.md](https://gist.github.com/PurpleBooth/b24679402957c63ec426) for details on our code of conduct, and the process for submitting pull requests to us.

## Authors

* **Norbert Kozsir** (@Norbert515) – _Initial work_, Former Head of Flutter development at Neohelden GmbH
* **Pascal Stech** (@Curvel) – _Maintainer_, Flutter Developer at Neohelden GmbH (NeoSEALs team)
* **Maik Hummel** (@Beevelop) – _Maintainer_, CTO at Neohelden GmbH (Daddy of the NeoSEALs team)

See also the list of [contributors](https://github.com/freemansoft/Flutter-AdaptiveCards/contributors) who participated in this project.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
