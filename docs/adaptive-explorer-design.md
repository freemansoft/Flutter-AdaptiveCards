# Adaptive Explorer design (sample program)

> **Example (adaptive_explorer sample):** [`adaptive_explorer/`](../adaptive_explorer/) is a desktop demonstration app, not a published package. It exercises [`flutter_adaptive_cards_fs`](../packages/flutter_adaptive_cards_fs/) and [`flutter_adaptive_template_fs`](../packages/flutter_adaptive_template_fs/). See [`documentation-scope.md`](documentation-scope.md).

## Purpose

Adaptive Explorer is a **design tool** for Adaptive Cards. It lets authors and integrators **preview a JSON card representation** as it will render in the Flutter renderer—without embedding cards in a host application.

The app is built around two JSON inputs:

| Input                    | Role                                                                                                     |
| ------------------------ | -------------------------------------------------------------------------------------------------------- |
| **Card JSON (template)** | An Adaptive Card payload that may include templating expressions (`${…}`) and acts as the card template. |
| **Data JSON (optional)** | Host or scenario data merged into the template before preview.                                           |

When both are loaded, Adaptive Explorer uses the templating library to **merge data JSON with the card template** and shows the **merged result** in the preview pane. You can also inspect the merged JSON in a dedicated editor tab. Opening only a template (no data file) previews the card as-is, leaving templating placeholders unresolved.

## What you see in the app

The UI splits into a **live preview** and an **editor**:

- **Preview pane** — Renders the current card (template only, or merged template + data) with `flutter_adaptive_cards_fs`.
- **Editor tabs** — JSON editors for the template, optional data, and the computed merged payload.

File-system watching reloads the preview when template or data files change on disk, so external editors stay in sync with the tool.

Chart element types (`Chart.Line`, `Chart.Donut`, etc.) are **not** registered in this app; use [widgetbook](../widgetbook/) to preview chart samples.

## Supported platforms

Desktop only: Windows, macOS, and Linux.

## Further reading

Operational details (App Bar actions, tab layout, known issues, getting started) are in [`adaptive_explorer/README.md`](../adaptive_explorer/README.md).
