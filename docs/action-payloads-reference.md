---
doc_type: reference
---

# Action payload reference

The invoke payload each action builds and the host callback it targets. For how actions flow
from JSON to execution (dispatch, rationale, custom actions, per-action behaviors), see
[`actions-architecture.md`](actions-architecture.md).

## Host action callbacks

Submit, Execute, and OpenUrl are **not** configured on `AdaptiveCardsCanvas`. Wrap the card with **`InheritedAdaptiveCardHandlers`**.

## Action.Submit payload

When **`DefaultSubmitAction`** runs:

1. Start from action JSON **`data`** (object or empty).
2. If **`associatedInputs`** is not **`"none"`** (default / omitted = **`"auto"`**), merge **`collectInputValues()`** (input ids overwrite duplicate keys in `data`). When **`"none"`**, invoke **`data`** is action JSON **`data`** only — no input values.
3. Build **`SubmitActionInvoke`** with merged **`data`** and action **`id`** (`actionId`).
4. Call **`InheritedAdaptiveCardHandlers.onSubmit(invoke)`**.

## Action.Execute payload

When **`DefaultExecuteAction`** runs:

1. Start from action JSON **`data`** (object or empty).
2. If **`associatedInputs`** is not **`"none"`** (default / omitted = **`"auto"`**), merge **`collectInputValues()`** (input ids overwrite duplicate keys in `data`). When **`"none"`**, invoke **`data`** is action JSON **`data`** only — no input values.
3. Build **`ExecuteActionInvoke`** with merged **`data`**, action **`verb`**, and action **`id`** (`actionId`).
4. Call **`InheritedAdaptiveCardHandlers.onExecute(invoke)`**.

Hosts route Teams-style Execute actions on **`invoke.verb`**. Per-action **`associatedInputs`** on Submit and Execute follows the same **`auto`** / **`none`** semantics as **`Data.Query`** — see [Dependent ChoiceSet (country → city)](form-inputs.md#dependent-choiceset-country--city).

## Action.OpenUrl payload

When **`DefaultOpenUrlAction`** runs:

1. Build **`OpenUrlActionInvoke`** with action **`url`** (or `altUrl` from selectAction routing) and optional action **`id`** (`actionId`).
2. Call **`InheritedAdaptiveCardHandlers.onOpenUrl(invoke)`**.

## Action.OpenUrlDialog payload

When **`DefaultOpenUrlDialogAction`** runs:

1. Build **`OpenUrlDialogActionInvoke`** with action **`url`** and optional action **`id`** (`actionId`).
2. Call **`InheritedAdaptiveCardHandlers.onOpenUrlDialog(invoke)`**.

## Action.Http payload (deprecated/legacy)

> **Deprecated/legacy:** `Action.Http` was the original Adaptive Cards HTTP action model (schema v1.0). It was superseded by `Action.Execute` (the [Universal Action Model](https://learn.microsoft.com/en-us/adaptive-cards/authoring-cards/universal-action-model), schema v1.4) and no longer renders in newer SDKs/schemas, but is still used by [Outlook Actionable Messages](https://learn.microsoft.com/en-us/outlook/actionable-messages/adaptive-card). Prefer `Action.Execute`/`Action.Submit` for new cards. The core library forwards the request and **never performs it**; wire `flutter_adaptive_cards_host_fs` (`AdaptiveHttpExecutor`) for the actual transport.

When **`DefaultHttpAction`** runs:

1. **`validateInputs`** — abort (marking fields) if any required/regex/range input is invalid, like `Action.Submit`.
2. **`collectInputValues()`**, then resolve **`{{inputId.value}}`** substitution (via `substituteInputValues`) in **`url`**, **`body`**, and each header **`value`**.
3. Gate the resolved **`url`** through the active **URI policy** (`InheritedAdaptiveCardSecurityPolicy.uriPolicy`); abort on denial, like `Action.OpenUrl`.
4. Debug-flag card-controlled sensitive headers (`Authorization`/`Cookie`). The header still forwards; the host decides.
5. Build **`HttpActionInvoke`** (`method`, resolved `url`/`body`/`headers`, raw `inputValues`, optional `actionId`) and call **`InheritedAdaptiveCardHandlers.onHttp(invoke)`** (nullable).

On the host side, `AdaptiveCardBackendHandlers.httpExecutor` performs the GET/POST and honors the Outlook response conventions: `CARD-UPDATE-IN-BODY: true` replaces the rendered card (reusing `onCardReplaced` + `cardValidator`), and `CARD-ACTION-STATUS` surfaces a failure message via `onError`.

## Input onChange payload

When an input value changes, **`RawAdaptiveCardState.changeValue`** builds **`InputChangeInvoke`** (`inputId`, `value`, `dataQuery`, `cardState`) and calls the host **`onChange`** handler (from **`AdaptiveCardsCanvas.onChange`** or **`InheritedAdaptiveCardHandlers.onChange`**).

## Root card `refresh` payload

When the root card JSON defines **`refresh.action`**, the library may fire a refresh invoke in two cases:

1. **Manual** — the user taps the refresh affordance (top-right icon on the root card).
2. **Auto-expire** — once after the first frame when **`refresh.expires`** is in the past.

Auto-refresh is gated by **`refresh.userIds`**: when that list is non-empty, auto-refresh runs only when **`AdaptiveCardsCanvas.currentUserId`** (exposed via **`currentUserIdProvider`**) is in the list. Manual refresh is not gated by **`userIds`**.

The invoke is built like **`Action.Execute`**: merge nested action **`data`** with **`collectInputValues()`** (honoring **`associatedInputs`** on the nested action), then:

1. Build **`RefreshActionInvoke`** with merged **`data`**, action **`verb`**, and optional action **`id`** (`actionId`).
2. Call **`InheritedAdaptiveCardHandlers.onRefresh(invoke)`** when set; otherwise fall back to **`onExecute`** with the same merged payload as **`ExecuteActionInvoke`**.

The library does not perform bot round-trips; the host replaces card JSON when refresh completes (for example by updating the map passed to **`RawAdaptiveCard`**).

Implemented in [workstream B](./superpowers/plans/2026-06-08-refresh-icon-charts-text-features.plan.md#workstream-b--refresh-property-v14) of the June 2026 plan. **Example (widgetbook sample):** **AdaptiveCard → Refresh** (`widgetbook/lib/refresh_demo_page.dart`).
