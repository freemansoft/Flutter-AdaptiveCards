# widgetbook for Flutter Adaptive Cards

A trashy use of the [Widgetbook](https://widgetbook.io) library from [Widgetbook pub.dev](https://pub.dev/packages/widgetbook) to view various json adaptive card samples in the Flutter Adaptive Cards project. The goal is to use this to explore rendering adaptive cards in Flutter. This is mostly json file driven and there is no way to manipulate any of the properties of the adaptive cards to see how they render.

## Refresh the code generated after every change in the use cases. You must refresh and restart to see json file changes

```bash
fvm dart run build_runner build
fvm flutter run
```

## Adding a new category or directory of json samples

Remember to add any new directory in lib/samples to the asset list in `pubspec.yaml`

## Interactive host demos (not JSON-only)

Some use cases wire host callbacks so behavior is visible beyond static card JSON:

| Widgetbook path | Page | Behavior |
| --- | --- | --- |
| **TextBlock** → Text overlay (knob) | `lib/text_block_overlay_page.dart` | Knob drives `setText` on a `TextBlock` |
| **Input.ChoiceSet** → Value changed action (host cascade) | `lib/dependent_choice_set_demo_page.dart` | Country `valueChangedAction` resets city; shared `onChange` repopulates city choices (`value_changed_action_filtered.json`). Filtered country picker searches/displays **titles**; submit uses **values**. |
| **Input.ChoiceSet** → Value changed action (Teams Data.Query) | same page, different JSON | Same handler; city uses `choices.data` / filtered style (`value_changed_action_dependent_query.json`). Filtered city list/search uses **titles**; values submitted on pick. |

Both dependent ChoiceSet use cases share **`handleDependentChoiceSetChange`**: the country branch runs for both; the city / `Data.Query` branch runs only when the card defines `choices.data`. See [Dependent ChoiceSet (country → city)](../docs/form-inputs.md#dependent-choiceset-country--city).

## mac OS changes

1. Outgoing connections had to be enabled in the Runner Signing & Capabilities
