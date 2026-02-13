# This project uses Flutter form for all AdaptiveCard Input types

All input types have a choice of using basic flutter widgets or using flutter form widgets.  This project is standardizing on flutter forms.

## Input.xxx Adaptive card inputs

- AdaptiveCard inputs are located in `flutter_adpative_cards/lib/src/elements/inputs`.  Each class there should have its own associated unit test class in `flutter_adaptive_cards/test/elements/inputs`.

## Comoponent field implementations

All of the data entry components in lib/src/elements/inputs should be form componets instead of plain flutter inputs.

- Existing Flutter widget text inputs, selection inputs and the other types should be replaced with their form equivalent where possible

## Unit tests

Input unit tests should be created for all input components and include the following.

- Layout for all display option combinations including labels, separators, tooltips and others where they exists. The test files should ahve the same name as the input class file with an added `_test.dart`.
- Input validation for mandatory fields and the messages.
- Loading from JSON.  Card json specifications can be a JSON file or a `map` that is the same as the map loaded from json.
- Initial values loaded from the source json and validated.
- Changing values in an input via UI action should result in the same value via the component API.
- For classes like choice_set, all of the combinations that change layout are tested. `compact`, `multiselect` and their JSON equivalents "compact" and "isMultiSelect".
- Adaptive component widget keys should be validated along with the input field widget keys.
- IDs in the json should be validated against the actual form input ids.

## Key naming changes 2026 Jan 30

Keys should match the following.

- An adaptive card's widget key is the id geven for the adaptive card plus `_adaptive` using the function `generateAdaptiveWidgetKey()`
- The widget key for the actual input field is the id given to the adaptive card using `generateWidgetKey()`
- The widget key for the actual value/display widget for any non-input widgets should be generated using `generateAdaptiveWidgetKey()`

Example:

- An DateInput  field map in the JSON has an `id` of `lastname`.
- The Adaptive input card widget Key would be `lastName_adaptive`
- The actual input field inside the card would have a lastname of `lastName` so that when the field is submitted the key for the fields value would be `lastname`.
- Selectors inside field bound to possible selections would have a widget key name of `lastName_<item_key>` or `lastName_<item_value`>

### Previous conventions

This key naming scheme was previously soething like the following

- An DateInput the field map in the JSON has an `id` of `lastname`.
- The Adaptive input card widget Key would be `lastName_adaptive`
- The actual input field inside the card would have a lastname of `lastName`
- Selectors inside field bound to possible selections would have a widget key name of `lastName_<item_key>` or `lastName_<item_value`>
