# Backend Host Integration

**Status**: ✅ Current | **Category**: Feature Spec

This document describes how to connect **`flutter_adaptive_cards_fs`** to a backend flow-service (custom REST API or Teams/Bot Framework–shaped invoke). Implementation lives in optional package **`flutter_adaptive_cards_host_fs`**.

**Related:**

- [optional-packages-and-extensions.md](./optional-packages-and-extensions.md) — why the host package is separate from core
- [actions-architecture.md](./actions-architecture.md) — typed invoke callbacks on `InheritedAdaptiveCardHandlers`
- [form-inputs.md](./form-inputs.md) — `associatedInputs` and dependent ChoiceSets
- [reactive-riverpod.md](./reactive-riverpod.md#server-driven-patches-host-package) — how response effects map to overlays
- [Package README](../packages/flutter_adaptive_cards_host_fs/README.md) — API quick reference
- Design history: [archived spec](./archive/specs/2026-06-07-backend-host-integration-design.md) · [implementation plan](./superpowers/plans/2026-06-07-backend-host-integration.plan.md)

---

## When to use which layer

| Need                                                                                | Package                                                 |
| ----------------------------------------------------------------------------------- | ------------------------------------------------------- |
| Render cards; wire callbacks manually                                               | **`flutter_adaptive_cards_fs`** only                    |
| Teams-correct invoke **payloads** (`associatedInputs` on Submit/Execute/Data.Query) | Core (Phase 1 — always available)                       |
| Serialize → POST → parse → apply patches automatically                              | **`flutter_adaptive_cards_host_fs`** (Phase 2 — opt in) |

Phase 2 depends on Phase 1 but Phase 1 is useful without the host package.

---

## Architecture

```mermaid
flowchart LR
  user[User action] --> handlers[AdaptiveCardBackendHandlers]
  handlers --> req[AdaptiveCardInvokeRequest]
  req --> adapter[PlainJson or Teams adapter]
  adapter --> client[AdaptiveCardBackendClient.post]
  client --> parse[AdaptiveCardInvokeResponse]
  parse --> apply[applyTo on RawAdaptiveCardState]
  apply --> overlays[Document overlays / onCardReplaced]
```

1. User triggers Submit, Execute, Refresh, or input `onChange`.
2. **`AdaptiveCardBackendHandlers`** builds **`AdaptiveCardInvokeRequest`**, serializes via adapter, **`POST`s** through **`AdaptiveCardBackendClient`**.
3. Response JSON parses to **`AdaptiveCardInvokeResponse`** with ordered **effects**.
4. **`response.applyTo(cardState)`** writes overlays via core APIs (`applyUpdates`, validation errors) or calls **`onCardReplaced`** for full card JSON.

---

## Quick start

```dart
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_adaptive_cards_fs/flutter_adaptive_cards_fs.dart';
import 'package:flutter_adaptive_cards_host_fs/flutter_adaptive_cards_host_fs.dart';

final cardKey = GlobalKey<RawAdaptiveCardState>();

AdaptiveCardBackendHandlers(
  client: HttpAdaptiveCardBackendClient(
    endpoint: Uri.parse('https://api.example.com/adaptive-card/invoke'),
  ),
  cardKey: cardKey,
  onError: (error) => log('invoke failed', error: error),
).wrap(
  RawAdaptiveCard.fromMap(
    key: cardKey,
    map: cardJson,
    hostConfigs: HostConfigs(),
  ),
  onCardReplaced: (map) => setState(() => cardJson = map),
);
```

**Requirements:**

- The same **`GlobalKey<RawAdaptiveCardState>`** on **`AdaptiveCardBackendHandlers`** and **`RawAdaptiveCard`** (Submit/Execute/Refresh resolve state from the key).
- **`InputChangeInvoke`** uses **`invoke.cardState`** directly (no key lookup).
- Provide **`onCardReplaced`** when the backend may return full replacement card JSON.

---

## Phase 1 — Invoke payloads in core

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

Root **`refresh.action`** uses the same Execute-shaped payload; see [refresh callback](actions-architecture.md#root-card-refresh-payload).

**MVP limitation:** Card-wide `auto` collection. Container-scoped `associatedInputs` is a documented follow-up.

---

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

---

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

---

## Error handling

| Case                                           | Behavior                                                       |
| ---------------------------------------------- | -------------------------------------------------------------- |
| Network failure                                | **`onError`** invoked; card unchanged                          |
| Malformed JSON / parse failure                 | **`AdaptiveCardInvokeResponseParseException`** → **`onError`** |
| Unknown effect `type`                          | Skipped in release; debug log                                  |
| **`replaceCard`** without **`onCardReplaced`** | **`StateError`** from **`applyTo`**                            |

Always provide **`onError`** in production hosts (SnackBar, retry UI, logging).

---

## Root card refresh

**`AdaptiveCardBackendHandlers`** wires **`onRefresh`** the same as Execute: builds **`AdaptiveCardInvokeRequest`** from **`RefreshActionInvoke`**, POSTs, applies effects. Host replaces card JSON when the response includes **`replaceCard`** or patches fields in place.

**Example (widgetbook sample):** **AdaptiveCard → Refresh** (`widgetbook/lib/refresh_demo_page.dart`).

---

## Custom transport

Implement **`AdaptiveCardBackendClient`** for gRPC, WebSocket, or in-memory tests:

```dart
class MockBackendClient implements AdaptiveCardBackendClient {
  @override
  Future<Map<String, dynamic>> post(Map<String, dynamic> body) async {
    return {'type': 'adaptiveCard.invokeResponse', 'effects': []};
  }
}
```

Tests: `packages/flutter_adaptive_cards_host_fs/test/`.

---

## Consumer checklist

```yaml
dependencies:
  flutter_adaptive_cards_fs: ^0.10.0
  flutter_adaptive_cards_host_fs: ^0.10.0
```

1. Add both packages.
2. Create shared **`GlobalKey<RawAdaptiveCardState>`**.
3. Wrap **`RawAdaptiveCard`** with **`AdaptiveCardBackendHandlers.wrap(...)`**.
4. Implement **`onCardReplaced`** if the server can return full card JSON.
5. Handle **`onError`** for network/parse failures.
6. (Optional) Switch to **`TeamsInvokeAdapter`** for Bot Framework APIs.

---

## Verification

```bash
cd packages/flutter_adaptive_cards_host_fs
fvm flutter test
```

Core **`associatedInputs`** tests live in `packages/flutter_adaptive_cards_fs/test/utils/associated_inputs_test.dart` and related input tests.

---

_Last updated: 2026-06-09_
