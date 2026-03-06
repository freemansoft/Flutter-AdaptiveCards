# adaptive_explorer

A design studio for the flutter_adaptive_cards_plus library. This viewer and editor for adaptive cards json files lets you open and render adaptive cards. It has a an editor capability that lets you edit a card in one tab and then render it in the preview tab.

Can be used to open a json file and display it. Will refresh the display if an outside editor updates the source file

## Known Issues

- The editor window can have text overflow for wide json files. Making the editor window wider will fix this issue.

## Features

- Has an "Open Template" button on the App Bar that lets you select a JSON template file to open
  - The app will Open the selected json template file and display it using the AdaptiveCards library.
  - The app will keep a list of recently opened files and allow you to open them again.
  - The app will watch the currently opened file and reload the display if the file modification date or contents change
  - The screen is blank if no template file is selected
- Has an "Open Data" button on the App Bar that lets you select an optional json data file to open.
  - The app will open the selected json data file and load it into memory.
  - The app will use the templating merge library to merge he data json with the template json and will then display the results.
  - The screen is blank if no template file is selected
- The application will display the template json as a rendered adaptive card whenever the user opens a template file and will refresh the display of the rendered card if the contents of the template or optional data file are touched or modified outside of this program
- Has a main view that is a tab view that lets you view the template json, the data json, and the merged json. This editor functionality sits next to the preview pane. The preview pane is above the editor pain when in portrait mode and to the left when in landscape mode.
  - The template json tab will display the template json in a json editor using json_editor_flutter
  - The data json tab will display the data json as a json editor using json_editor_flutter
  - The template and data editors have save functionality
  - The merged json tab will display the merged json as a json editor using json_editor_flutter
- The divider bar between the preview pane and the editor view can be be moved to change the relative width

## Supported platforms

This application runs on any desktop: macos, windows or linux

- Windows
- MacOS
- Linux

## Tests

This project should have both unit and integration tests

- unit tests in the `test` directory
- integration tests in the `integration_test` directory
- Run the tests using `flutter test`

## Getting Started

1. Run this app
2. Click on the template open button and select the template json files. The file can be an actually template or a fully hydrated AdaptiveCard json file.

## MacOS Specifics

- The app uses the file_picker package to open files. This requires the app to be signed with a valid certificate.
- File permissions have been enabled in the entitlements file for the app to enable fetching and saving of sample files
  - `	<key>com.apple.security.files.user-selected.read-write</key>`
- Network permissions have been enabled in the entitlements file for the app to enable fetching of network images.
  - `	<key>com.apple.security.network.client</key>`
