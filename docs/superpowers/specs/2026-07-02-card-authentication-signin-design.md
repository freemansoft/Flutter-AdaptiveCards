# Adaptive Card `authentication` — sign-in button path

_Design spec — 2026-07-02_

## Summary

Implement the Adaptive Cards v1.4 root **`authentication`** object, limited to the
**sign-in button path** (`buttons[].type == "signin"`). This closes the single
largest remaining spec gap in `flutter_adaptive_cards_fs` (root `authentication`
is currently `❌ Missing`, and it is both a root property **and** a host-handler
concern, which is what production Bot Framework / Teams hosts need).

The work is split across two packages, mirroring two existing precedents in this
repo — the root **`refresh`** feature and the **backend-invoke** split:

- **Phase 1 — `flutter_adaptive_cards_fs` (core):** parse `authentication`,
  render the sign-in region (text + buttons), and forward a typed
  `SigninActionInvoke` to a new nullable `onSignin` host handler. The core never
  performs network I/O.
- **Phase 2 — `flutter_adaptive_cards_host_fs` (host transport):** wire `onSignin`
  into `AdaptiveCardBackendHandlers`, open the sign-in URL via an app-supplied
  opener, expose a `completeSignin(...)` re-entry that POSTs a sign-in invoke and
  applies the response through the **existing effect pipeline** (a
  `ReplaceCardEffect` swaps in the real card).

## Goals

- Faithful v1.4 parsing of the root `authentication` object into a typed model.
- Render the sign-in affordance (text + one button per `AuthCardButton`, honoring
  `title` and `image`) the way the `refresh` manual affordance is rendered.
- A typed, testable host handoff (`onSignin` + `SigninActionInvoke`), with a
  sensible fallback when no handler is installed.
- A turnkey host-side sign-in round-trip in `flutter_adaptive_cards_host_fs` that
  reuses the existing invoke/effect machinery and card-replacement path.

## Non-goals

- **SSO / `tokenExchangeResource` token exchange** (silent AAD token exchange,
  `signin/tokenExchange` invoke, `412` needs-consent fallback). The
  `tokenExchangeResource` object is **parsed and preserved** on the model but is
  **not acted on**. This is an explicit future phase.
- A bundled webview / browser. Opening the OAuth URL and capturing the redirect
  is inherently platform-specific and remains the **app's** responsibility; the
  library provides the `onSignin` hook and the `completeSignin` re-entry only.
- Changes to any Riverpod provider or scope (none expected).

## Hard constraints

- **No new dependencies in `flutter_adaptive_cards_fs`.** Phase 1 is pure Dart
  models + existing Flutter/Material widgets + the library's existing image
  handling for button `image`. All transport/HTTP lives in Phase 2 inside
  `flutter_adaptive_cards_host_fs`, which already carries those dependencies.
- **Core never performs network I/O** — consistent with `refresh`, `Action.Http`,
  and backend invoke.
- **Never mutate the host JSON map** for runtime state (project rule); the auth
  region is derived from the baseline root map, same as `refresh`.

## Schema reference

The v1.4 root `authentication` object (Bot Framework OAuth model):

```json
"authentication": {
  "text": "Please sign in to continue",
  "connectionName": "myOAuthConnection",
  "tokenExchangeResource": { "id": "...", "uri": "...", "providerId": "..." },
  "buttons": [
    {
      "type": "signin",
      "title": "Sign in",
      "image": "https://example.com/signin.png",
      "value": "https://login.example.com/oauth/authorize?..."
    }
  ]
}
```

`AuthCardButton` fields: `type` (e.g. `"signin"`), `title`, `image` (URL),
`value` (the sign-in URL / action value).

## Phase 1 — core (`flutter_adaptive_cards_fs`)

### Models

New/changed files under `lib/src/models/`:

- **`authentication_config.dart`** — `AuthenticationConfig`
  (`text`, `connectionName`, `tokenExchangeResource` kept as a raw
  `Map<String, dynamic>?`, `buttons: List<AuthCardButton>`) with a
  `AuthenticationConfig.fromJson` factory, following `RefreshConfig`'s shape and
  fail-open parsing (unknown/malformed fields tolerated).
- **`AuthCardButton`** (same file) — `type`, `title`, `image`, `value`, with a
  `fromJson` factory. Only `type == "signin"` is actioned in this phase; other
  button types are parsed and rendered but tapping them is a no-op with a debug
  log (forward-compatible).
- **`action_invoke.dart`** — add `SigninActionInvoke`
  (`value` (sign-in URL), `connectionName`, optional `actionId`) alongside the
  existing invoke payloads, with a factory that builds from an `AuthCardButton`
  + the parent `AuthenticationConfig.connectionName`.

### Parsing + rendering

- `AdaptiveCardElement` reads `adaptiveMap['authentication']` at the same point it
  reads `refresh` (see `cards/adaptive_card_element.dart`), storing an
  `AuthenticationConfig? _authConfig`.
- Render an **auth region** (a private widget, e.g. `_AuthenticationRegion`,
  analogous to the manual refresh control): optional `text` line + one button per
  `AuthCardButton`. Button label from `title`; leading image from `image` via the
  library's existing image handling; semantics label from `title` (fall back to
  `type`).
- **Placement:** the auth region renders **below the card body and above the card
  actions** (in both the `Column` and `listView` paths). A widget test pins this
  order (body → sign-in → actions).
- Keys via the existing `generateAdaptiveWidgetKey` / `generateWidgetKey`
  helpers so button keys are deterministic from the root map.

### Handler

- Add a nullable field to `InheritedAdaptiveCardHandlers`:
  `final void Function(SigninActionInvoke invoke)? onSignin;`
  with `///` docs explaining the sign-in handoff and the fallback below.
- On a `signin` button tap → `onSignin?.call(SigninActionInvoke(...))`.
- **Fallback when `onSignin` is null:** if the button `value` is an http(s) URL,
  fall back to `onOpenUrl(OpenUrlActionInvoke(url: value))` so a bare card still
  does something useful (mirrors refresh→execute fallback). If `value` is not a
  URL and no handler is installed → no-op + debug log.

### Core tests

- `authentication_config_test.dart` — parse full object, missing `buttons`,
  malformed entries, `tokenExchangeResource` preserved.
- Widget test — auth region renders text + buttons; tapping a `signin` button
  fires `onSignin` with the expected `value`/`connectionName`; with `onSignin`
  null and a URL `value`, `onOpenUrl` is invoked instead.
- Golden — a card with an `authentication` region (added to the golden set;
  regenerate baselines for the affected platform only).

## Phase 2 — host transport (`flutter_adaptive_cards_host_fs`)

### Request model + adapters

- `models/invoke_request.dart` — add `AdaptiveCardInvokeRequest.fromSignin(...)`
  carrying the sign-in context (`connectionName`, `value`, and the
  app-supplied completion `state` / magic code).
- `adapters/plain_json_invoke_adapter.dart` — serialize the sign-in request in the
  package's plain-JSON shape (default).
- `adapters/teams_invoke_adapter.dart` — optional Teams-shaped variant using the
  Bot Framework `signin/verifyState` invoke name. Kept minimal; full Teams SSO is
  out of scope.

### Handler wiring

- `AdaptiveCardBackendHandlers` gains:
  - constructor hooks: an app-supplied **URL opener** callback and an optional
    `onSignin` override;
  - `wrap(...)` sets `InheritedAdaptiveCardHandlers.onSignin` to open the sign-in
    `value` URL via the opener (no bundled webview);
  - a public **`completeSignin({required state / magicCode})`** method the app
    calls when the OAuth redirect returns. It builds
    `AdaptiveCardInvokeRequest.fromSignin(...)`, POSTs via the existing `client`,
    parses via `responseParser`, and applies the result through the existing
    `AdaptiveCardInvokeResponse.applyTo(...)` — so a `ReplaceCardEffect` swaps in
    the real card, honoring the existing `cardValidator` guardrail.
- Reuses the existing `onError`, `cardKey`/`RawAdaptiveCardState` lookup, and
  bounded-JSON decoding.

### Host tests

- `fromSignin` serialization — PlainJson and Teams shapes.
- `completeSignin` round-trip — mock client returns a `replaceCard` response;
  assert the card is replaced via `onCardReplaced`, and that an untrusted card is
  rejected by `cardValidator`.
- Failure path — POST/parse error routes to `onError`.

## Data flow

```
authentication JSON
  → AuthenticationConfig (core parse)
  → auth region renders (text + buttons)
  → user taps signin button
  → onSignin(SigninActionInvoke)                     [core → host]
  → app opens sign-in URL, captures redirect          [app responsibility]
  → completeSignin(state)                             [host package]
  → POST AdaptiveCardInvokeRequest.fromSignin         [host → flow service]
  → responseParser → AdaptiveCardInvokeResponse
  → ReplaceCardEffect → real card renders
```

## Error handling

- Malformed / missing `authentication` or empty `buttons` → region omitted, debug
  log (fail-open, like other core parsers).
- Non-`signin` button tap → no-op + debug log.
- Null `onSignin` + non-URL `value` → no-op + debug log; URL `value` → `onOpenUrl`
  fallback.
- Phase 2 POST / parse failures → existing `onError` path.
- Untrusted replacement card from the flow service → rejected by the existing
  `cardValidator` (throws `AdaptiveCardInvokeResponseParseException`, card not
  applied).

## Documentation impact (architecture-sync gate)

Update in the same change set:

- `packages/flutter_adaptive_cards_fs/README.md` → Implementation status: root
  `authentication` `❌`→`✅` (button path; note SSO token-exchange deferred); note
  the new `onSignin` handler in the Actions/handler context.
- `docs/actions-architecture.md` — new `SigninActionInvoke` + `onSignin` handler
  and the sign-in handoff.
- `docs/backend-host-integration.md` — Phase 2 `completeSignin` round-trip.
- `docs/Implementation-Status.md` — move root `authentication` from the gap list;
  add a "Recently completed" entry.
- `packages/flutter_adaptive_cards_fs/CHANGELOG.md` and
  `packages/flutter_adaptive_cards_host_fs/CHANGELOG.md` — `## [Unreleased]`
  bullets for each package touched.
- `docs/reactive-riverpod.md` / `docs/hostconfig.md` — only if a provider or
  HostConfig section is touched (not expected).

## Verification (full suite — completion gate)

```bash
# Repo root
fvm flutter analyze

# Core library
cd packages/flutter_adaptive_cards_fs
fvm flutter test --exclude-tags=golden

# Host package
cd packages/flutter_adaptive_cards_host_fs
fvm flutter test --exclude-tags=golden

# Coverage gate (repo root, after --coverage runs)
fvm dart run tool/coverage/check_coverage.dart
```

Do not lower any coverage floor — add tests. Golden baselines for the new auth
region regenerate on the affected platform only.

## Open questions for review

1. ~~**Region placement**~~ — resolved: below body, above actions (see Rendering).
2. **Teams shape depth in Phase 2** — ship the `signin/verifyState` Teams adapter
   variant now, or PlainJson only and defer Teams shaping?
3. **`completeSignin` signature** — `state` string (magic code) only, or a small
   struct allowing future SSO token fields without a breaking change?
