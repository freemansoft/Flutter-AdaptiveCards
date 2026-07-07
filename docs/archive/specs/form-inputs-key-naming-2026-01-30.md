# Input widget key naming — historical notes (2026-01-30)

> 🗄️ **Historical.** Extracted from `docs/form-inputs.md`. For the current, canonical
> input widget-key generation rules, see
> [`AdaptiveWidget-Key-Generation.md`](../../AdaptiveWidget-Key-Generation.md). Kept here
> only as a record of the earlier naming scheme.

## Key naming changes 2026 Jan 30

Keys should match the following.

- An adaptive card's widget key is the id geven for the adaptive card plus `_adaptive` using the function `generateAdaptiveWidgetKey()`
- The widget key for the actual input field is the id given to the adaptive card using `generateWidgetKey()`
- The widget key for the actual value/display widget for any non-input widgets should be generated using `generateAdaptiveWidgetKey()`

Example:

- An DateInput field map in the JSON has an `id` of `lastname`.
- The Adaptive input card widget Key would be `lastName_adaptive`
- The actual input field inside the card would have a lastname of `lastName` so that when the field is submitted the key for the fields value would be `lastname`.
- Selectors inside field bound to possible selections would have a widget key name of `lastName_<item_key>` or `lastName_<item_value`>

### Previous conventions

This key naming scheme was previously soething like the following

- An DateInput the field map in the JSON has an `id` of `lastname`.
- The Adaptive input card widget Key would be `lastName_adaptive`
- The actual input field inside the card would have a lastname of `lastName`
- Selectors inside field bound to possible selections would have a widget key name of `lastName_<item_key>` or `lastName_<item_value`>
