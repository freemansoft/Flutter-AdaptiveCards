# adaptive_explorer

Viewer for adaptive cards json files. Can be used to open a json file and display it. Will refresh the display if an outside editor updates the source file

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
- The application will display the template json as an adaptive card whenever the user opens a template file and will refresh the dipslay if the contents of the template or optional data file are touched or modified outside of this program

This application runs on any desktop, macos, windows or linux

## Supported platforms

- Windows
- MacOS
- Linux

## Getting Started

1. Run this app
2. Click on the template open button and select the template json files. The file can be an actually template or a fully hydrated AdaptiveCard json file.
