# Action.Http design

- **Date:** 2026-06-26
- **Status:** Approved (brainstorming)
- **Packages:** `flutter_adaptive_cards_fs` (core), `flutter_adaptive_cards_host_fs` (host wiring)

## Summary

Add `Action.Http` as a general-purpose, author-driven HTTP action. The card author
bakes an HTTP `GET`/`POST` request (method, url, headers, body) directly into the
card; tapping the action collects input values, performs `{{inputId.value}}`
substitution, validates, and forwards a payload to the host. The host package gains
a default executor that actually performs the request.

`Action.Http` was the **original Adaptive Cards HTTP action model** (schema v1.0).
It was superseded by `Action.Execute` (the
[Universal Action Model](https://learn.microsoft.com/en-us/adaptive-cards/authoring-cards/universal-action-model),
schema v1.4) and no longer renders in newer SDKs/schemas, but is still used by
**Outlook Actionable Messages**
(<https://learn.microsoft.com/en-us/outlook/actionable-messages/adaptive-card>).
Because it is a **deprecated/legacy** action, every public surface (dartdoc,
`docs/`, README status table) must tag it **deprecated/legacy** so card authors
know to prefer `Action.Execute`/`Action.Submit`.

## Action.Http JSON contract

| Property  | Type                     | Required  | Notes                                     |
| --------- | ------------------------ | --------- | ----------------------------------------- |
| `type`    | String                   | yes       | `"Action.Http"`                           |
| `title`   | String                   | no        | Button label                              |
| `method`  | String                   | yes       | `GET` or `POST` (upper-cased on read)     |
| `url`     | String                   | yes       | Supports `{{inputId.value}}` substitution |
| `headers` | Array of `{name, value}` | no        | `value` supports substitution             |
| `body`    | String                   | POST only | Supports `{{inputId.value}}` substitution |

Substitution uses the literal Outlook `{{inputId.value}}` form only. This is distinct
from the `flutter_adaptive_template_fs` templating engine (`${...}`); the templating
engine is **not** involved.

## Decisions (from brainstorming)

1. **Execution model:** forward to a host callback. The lean core never makes the
   network call itself, matching `Action.Submit`/`Execute`/`OpenUrl`. Real transport
   lives in `flutter_adaptive_cards_host_fs`.
2. **Substitution:** the **library** resolves `{{inputId.value}}` in `url`, `body`, and
   each header `value`. The forwarded payload carries the **resolved** values plus the
   **raw** collected `inputValues` map and `actionId`, so hosts never re-implement the
   `{{}}` mini-language.
3. **Pre-flight guards (all three):**
   - Validate inputs first (`validateInputs`), aborting and marking fields on failure
     (like Submit/Execute).
   - Gate the resolved `url` through the active URI policy, aborting on denial (like
     OpenUrl).
   - Debug-log when card JSON sets a sensitive header (`authorization`/`cookie`,
     case-insensitive). The header still forwards; the host decides.
4. **Scope:** ship both the core forwarding hook (v1a) and host-package wiring (v1b)
   so the request works end-to-end.

## v1a — `flutter_adaptive_cards_fs` (core)

### New files

- `lib/src/cards/actions/http.dart` — `AdaptiveActionHttp`, a `StatefulWidget` with
  `AdaptiveElementWidgetMixin` (widget) and `AdaptiveActionMixin, AdaptiveElementMixin,
ProviderScopeMixin` (state), rendering through `IconButtonAction`. Mirrors
  `submit.dart`. Resolves `DefaultHttpAction` from the action type registry in
  `didChangeDependencies` and calls `action.tap(...)` on tap.
- `lib/src/utils/input_substitution.dart` — pure util
  `String substituteInputValues(String template, Map<String, dynamic> inputValues)`
  that replaces `{{id.value}}` tokens. Unknown ids resolve to empty string; non-token
  text passes through unchanged. Returns input unchanged when no tokens present.

### Changed files

- `lib/src/action/generic_action.dart` — add `abstract class GenericHttpAction extends
GenericAction` with the standard `tap({context, rawAdaptiveCardState, adaptiveMap})`
  contract.
- `lib/src/action/default_actions.dart` — add `DefaultHttpAction extends
GenericHttpAction`. `tap` order:
  1. `validateInputs(container)` → return if invalid.
  2. `collectInputValues()`.
  3. Resolve substitution in `url`, `body`, and header values.
  4. Gate resolved `url` via `InheritedAdaptiveCardSecurityPolicy.uriPolicyOf(context)`;
     on `AdaptiveUriDenied` show debug snackbar and return.
  5. Debug-log sensitive headers.
  6. Build `HttpActionInvoke` and forward to `InheritedAdaptiveCardHandlers.onHttp?`;
     if null, debug snackbar (matches existing "no handler" behavior).
- `lib/src/models/action_invoke.dart` — add `HttpActionInvoke`:
  - `method` (String, upper-cased), `url` (String, resolved), `body` (String?, resolved),
    `headers` (`List<HttpActionHeader>`, resolved), `inputValues`
    (`Map<String, dynamic>`, raw), `actionId` (String?).
  - Small value type `HttpActionHeader { final String name; final String value; }`
    (ordered list preserves author order and allows duplicate header names).
  - `HttpActionInvoke.fromActionMap(actionMap, inputValues)` factory performs the
    substitution using `substituteInputValues`.
- `lib/src/action/action_handler.dart` — add optional/nullable field
  `final void Function(HttpActionInvoke invoke)? onHttp;` to
  `InheritedAdaptiveCardHandlers` (nullable to avoid a breaking change to existing host
  constructions, same approach as `onRefresh`).
- `lib/src/action/action_type_registry.dart` — `DefaultActionTypeRegistry`:
  `case 'Action.Http': return const DefaultHttpAction();`.
- `lib/src/registry.dart` — `_getActionWidget`:
  `case 'Action.Http': return AdaptiveActionHttp(adaptiveMap: map);`.
- Barrel/exports as needed (`HttpActionInvoke`, `HttpActionHeader`, `AdaptiveActionHttp`,
  `GenericHttpAction`, `DefaultHttpAction`, `substituteInputValues`) following the
  pattern used for the other actions.

`Action.Http` is registered as a first-class built-in (hardcoded switch entries), **not**
via `CardTypeRegistry.addedActions`.

## v1b — `flutter_adaptive_cards_host_fs` (host wiring)

The existing `AdaptiveCardBackendClient.post(body)` posts to a **preconfigured**
endpoint and cannot accept a per-action URL, so `Action.Http` needs a dedicated executor.

- New `AdaptiveHttpExecutor` interface:
  `Future<AdaptiveHttpResult> execute(HttpActionInvoke invoke)` where
  `AdaptiveHttpResult` exposes status code, headers, and body string.
- New default `HttpAdaptiveHttpExecutor` built on the same `http` dependency used by
  `http_backend_client.dart`. Performs the `GET`/`POST` with the resolved url/headers/body.
- `AdaptiveCardBackendHandlers` gains an optional `httpExecutor` and wires `onHttp:` in
  `wrap()`:
  - On success, reuse the existing `onCardReplaced` path when the response carries
    `CARD-UPDATE-IN-BODY: true` (parse body as a replacement card).
  - Surface `CARD-ACTION-STATUS` (and transport failures) via the existing `onError`.
  - Fire-and-forget (`unawaited`), matching the other handlers.

## Testing

### Core (`packages/flutter_adaptive_cards_fs/test/`)

- `substituteInputValues`: single token, multiple tokens, missing id → empty, no-token
  passthrough, token inside larger string.
- `AdaptiveActionHttp`: renders a button with `title`; tap with no `onHttp` handler does
  not throw.
- `DefaultHttpAction.tap`: aborts when a required input is invalid; aborts (no forward)
  when the URI policy denies the resolved url; forwards a `HttpActionInvoke` with resolved
  url/body/headers + raw `inputValues` + `actionId`; sensitive-header debug flag path.
- Registry: `DefaultActionTypeRegistry` returns `DefaultHttpAction`; `_getActionWidget`
  returns `AdaptiveActionHttp` for `Action.Http`.

### Host (`packages/flutter_adaptive_cards_host_fs/test/`)

- `HttpAdaptiveHttpExecutor`: GET and POST issue the expected request; headers passed
  through; result exposes status/body.
- `AdaptiveCardBackendHandlers.onHttp`: card replacement on `CARD-UPDATE-IN-BODY`; error
  surfaced via `onError`.

Tests run in the golden-excluded pass to satisfy the coverage gate.

## Docs & gates (same change)

- `packages/flutter_adaptive_cards_fs/README.md` — add `Action.Http` to the
  Implementation-status table, tagged deprecated/legacy.
- `docs/` — update action references and the handlers list in
  `docs/reactive-riverpod.md`; grep `onRefresh` / handler lists to keep in sync. Update
  the `adaptive-cards-backend-host` notes for the host executor.
- **CHANGELOG:** add the Action.Http bullet to the existing `## [0.13.0]` block in
  **both** `flutter_adaptive_cards_fs/CHANGELOG.md` and
  `flutter_adaptive_cards_host_fs/CHANGELOG.md` (not `Unreleased`).
- Final verification: `fvm flutter analyze`; both package test suites
  (`--exclude-tags=golden`); coverage gate
  (`fvm dart run tool/coverage/check_coverage.dart`).

## Out of scope (YAGNI)

- `autoInvokeAction` card-level auto-refresh.
- `expectedActors` / `correlationId` / JWT (`Authorization`) auth injection.
- Built-in fetch in the core library.
- Templating-engine (`${...}`) integration — only the literal `{{id.value}}` form.
