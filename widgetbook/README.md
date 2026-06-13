# widgetbook for Flutter Adaptive Cards

**Sample / demonstration app** (not published). Showcases how the library packages render Adaptive Card JSON and optional host callbacks. Package architecture is documented under `docs/` and `packages/*/README.md` — see [`docs/documentation-scope.md`](../docs/documentation-scope.md).

A trashy use of the [Widgetbook](https://widgetbook.io) library from [Widgetbook pub.dev](https://pub.dev/packages/widgetbook) to view various json adaptive card samples in the Flutter Adaptive Cards project. The goal is to use this to explore rendering adaptive cards in Flutter. This is mostly json file driven and there is no way to manipulate any of the properties of the adaptive cards to see how they render.

## Refresh the code generated after every change in the use cases. You must refresh and restart to see json file changes

```bash
fvm dart run build_runner build
fvm flutter run
```

## Adding a new category or directory of json samples

When you add JSON under a **new** folder in `lib/samples/` (for example `lib/samples/v1.4/`):

1. **Register the directory** in [`pubspec.yaml`](pubspec.yaml) under `flutter: assets:` — Flutter only bundles declared asset paths; `AdaptiveCardsCanvas.asset` will fail at runtime if the folder is missing from this list.
2. Add a `@widgetbook.UseCase` in [`lib/adaptive_cards_use_cases.dart`](lib/adaptive_cards_use_cases.dart) (or a dedicated overlay page when host callbacks are required).
3. Regenerate Widgetbook directories and restart the app (see below).

Existing sample roots already listed in `pubspec.yaml` include `lib/samples/charts/`, `lib/samples/v1.4/`, `lib/samples/v1.5/`, `lib/samples/v1.6/`, and per-element folders such as `lib/samples/text_block/`.

## Interactive host demos (not JSON-only)

Some use cases wire host callbacks so behavior is visible beyond static card JSON.

**Host-overlay knob demos** (`setText`, `setFacts`, `clearFacts`, …) follow a shared pattern (page `GlobalKey`, post-frame apply queue, registry). See [`docs/widgetbook-overlay-demos.md`](../docs/widgetbook-overlay-demos.md).

| Widgetbook path                                               | Page                                      | Behavior                                                                                                                                                                                                   |
| ------------------------------------------------------------- | ----------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **TextBlock** → Text overlay (knob)                           | `lib/text_block_overlay_page.dart`        | Knob drives `setText` on a `TextBlock`                                                                                                                                                                     |
| **FactSet** → Facts overlay (knob)                            | `lib/fact_set_overlay_page.dart`          | Dropdown presets drive `setFacts` / `clearFacts` on `demoFactSet`                                                                                                                                          |
| **Input.ChoiceSet** → Value changed action (host cascade)     | `lib/dependent_choice_set_demo_page.dart` | Country `valueChangedAction` resets city; shared `onChange` repopulates city choices (`value_changed_action_filtered.json`). Filtered country picker searches/displays **titles**; submit uses **values**. |
| **Input.ChoiceSet** → Value changed action (Teams Data.Query) | same page, different JSON                 | Same handler; city uses `choices.data` / filtered style (`value_changed_action_dependent_query.json`). Filtered city list/search uses **titles**; values submitted on pick.                                |
| **AdaptiveCard** → Refresh                                    | `lib/refresh_demo_page.dart`              | Manual refresh affordance; **`onRefresh`** SnackBar (`lib/samples/v1.4/refresh_demo.json`)                                                                                                                 |

Both dependent ChoiceSet use cases share **`handleDependentChoiceSetChange`**: the country branch runs for both; the city / `Data.Query` branch runs only when the card defines `choices.data`. See [Dependent ChoiceSet (country → city)](../docs/form-inputs.md#dependent-choiceset-country--city).

## mac OS changes

1. Outgoing connections had to be enabled in the Runner Signing & Capabilities
