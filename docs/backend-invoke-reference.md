---
doc_type: reference
---

# Backend invoke protocol reference

Wire-level reference for the backend invoke round-trip: request payloads core builds, request
adapters, the response contract, effect apply order, and error behavior. For the setup
walkthrough (how to wire `AdaptiveCardBackendHandlers`, sign-in, custom transport), see the
how-to guide [`backend-host-integration.md`](backend-host-integration.md).

## Invoke payloads in core (Phase 1)

Before adding the host package, core already builds backend-ready invoke objects.

### `Data.Query` (`choices.data`)

| `associatedInputs`  | Behavior                                                                       |
| ------------------- | ------------------------------------------------------------------------------ |
| omitted or `"auto"` | Merge sibling input values into `dataQuery.parameters` (firing input excluded) |
| `"none"`            | JSON `parameters` only                                                         |

See [Dependent ChoiceSet](form-inputs.md#dependent-choiceset-country--city).

### `Action.Submit` / `Action.Execute` / root `refresh`

| `associatedInputs`  | Behavior                                  |
| ------------------- | ----------------------------------------- |
| omitted or `"auto"` | Merge all input values into action `data` |
| `"none"`            | Action JSON `data` only                   |

Root **`refresh.action`** uses the same Execute-shaped payload; see [refresh callback](action-payloads-reference.md#root-card-refresh-payload).

**MVP limitation:** Card-wide `auto` collection. Container-scoped `associatedInputs` is a documented follow-up.

## Request adapters

| Adapter                                | Use case                                                       |
| -------------------------------------- | -------------------------------------------------------------- |
| **`PlainJsonInvokeAdapter`** (default) | Custom flow-services; flat JSON with `kind`, `verb`, `data`, … |
| **`TeamsInvokeAdapter`**               | Bot Framework–shaped invoke activities                         |

```dart
AdaptiveCardBackendHandlers(
  client: client,
  cardKey: cardKey,
  requestAdapter: TeamsInvokeAdapter.toMap,
  responseParser: TeamsInvokeAdapter.responseFromMap,
  ...
)
```

OpenUrl actions are **not** sent to the backend by default; pass **`onOpenUrl`** / **`onOpenUrlDialog`** overrides on **`AdaptiveCardBackendHandlers`** when needed.

## Response contract (PlainJson)

Wrapper type: `"type": "adaptiveCard.invokeResponse"`.

### Effect types and apply order

Effects run **in array order**. Recommended server order:

1. **`applyPatches`** — dynamic element updates (choices, visibility, text, …)
2. **`setInputErrors`** — validation messages on inputs
3. **`replaceCard`** — full card JSON swap (requires host **`onCardReplaced`**)

**Patches + errors example:**

```json
{
  "type": "adaptiveCard.invokeResponse",
  "effects": [
    {
      "type": "applyPatches",
      "elements": [
        {
          "id": "city",
          "choices": [{ "title": "Paris", "value": "paris" }]
        }
      ]
    },
    {
      "type": "setInputErrors",
      "errors": { "email": "Invalid format" }
    }
  ]
}
```

**Full replacement shorthand:**

```json
{
  "type": "adaptiveCard.invokeResponse",
  "card": { "type": "AdaptiveCard", "version": "1.5", "body": [] }
}
```

Each patch element uses **`AdaptiveElementUpdate`** fields (`choices`, `clearValue`, `errorMessage`, `isVisible`, `text`, `facts`, …). Internally, **`ApplyPatchesEffect`** calls **`RawAdaptiveCardState.applyUpdates`**. **`SetInputErrorsEffect`** maps to validation overlays. See [Server-driven patches](reactive-riverpod.md#server-driven-patches-host-package).

## Error handling

| Case                                           | Behavior                                                       |
| ---------------------------------------------- | -------------------------------------------------------------- |
| Network failure                                | **`onError`** invoked; card unchanged                          |
| Malformed JSON / parse failure                 | **`AdaptiveCardInvokeResponseParseException`** → **`onError`** |
| Unknown effect `type`                          | Skipped in release; debug log                                  |
| **`replaceCard`** without **`onCardReplaced`** | **`StateError`** from **`applyTo`**                            |

Always provide **`onError`** in production hosts (SnackBar, retry UI, logging).
