# Changelog

## [0.15.0]

- no changes yet

## [0.14.0]

### Added 0.14.0

- Add card `authentication` sign-in support: `AdaptiveCardBackendHandlers` opens
  the sign-in URL via `urlOpener` and `completeSignin(state:)` POSTs a signin
  invoke (`signin/verifyState` for Teams) whose `replaceCard` response swaps in
  the returned card. Adds `AdaptiveCardInvokeKind.signin`, `AdaptiveCardInvokeRequest.fromSignin`, and `connectionName` field on the request model.

### Docs 0.14.0

- **README:** "How actions reach your handlers" is now a short host-focused summary (when your callback fires vs. not) that links to the canonical per-action table and dispatch diagrams in `docs/actions-architecture.md`. The full `GenericAction` → `InheritedAdaptiveCardHandlers` table + a component and sequence diagram moved there; `docs/backend-host-integration.md` gained sequence diagrams for the invoke and sign-in round-trips.

## [0.13.0]

### Added 0.13.0

- **`Action.Http` transport (deprecated/legacy action)** — `Action.Http` is the original Adaptive Cards HTTP action model (schema v1.0), superseded by `Action.Execute` (Universal Action Model, schema v1.4) and still used by Outlook Actionable Messages. New `AdaptiveHttpExecutor` interface and default `HttpAdaptiveHttpExecutor` (built on `package:http`) perform the card-authored `GET`/`POST`. `AdaptiveCardBackendHandlers` gains an optional `httpExecutor` and wires the core `onHttp` callback: on success it honors `CARD-UPDATE-IN-BODY: true` by replacing the rendered card (reusing `onCardReplaced` + `cardValidator`), and surfaces `CARD-ACTION-STATUS` / non-2xx failures via `onError`. Response bodies are byte-capped.

### Changed 0.13.0

- **Docs:** README now has an **Implementation status** section summarizing Phase 1 / Phase 2 coverage and linking to the central status matrix.

### Tests 0.13.0

- Expanded `AdaptiveCardBackendHandlers` tests to cover Execute / Refresh / onChange invoke kinds and both error paths (missing mounted card state, backend `post` failure), bringing `backend_handlers.dart` to full coverage.

## [0.12.0]

### Security 0.12.0

- **Bounded backend response decoding:** `HttpAdaptiveCardBackendClient` gains `maxResponseBytes` (default 1 MiB) and decodes via `decodeJsonMapWithLimit`, throwing `AdaptiveJsonTooLargeException` on oversized bodies instead of decoding unbounded untrusted JSON.
- **Optional `replaceCard` validator:** `AdaptiveCardInvokeResponse.applyTo` and `AdaptiveCardBackendHandlers.wrap` accept an `AdaptiveCardValidator`; a backend-supplied replacement card that fails validation is rejected (`AdaptiveCardInvokeResponseParseException`) and never rendered.

## [0.11.0]

- no changes yet

## [0.10.0]

- Initial release: `AdaptiveCardInvokeRequest`, PlainJson and Teams adapters, `AdaptiveCardInvokeResponse` with `applyTo`, `HttpAdaptiveCardBackendClient`, and `AdaptiveCardBackendHandlers`.
- **`AdaptiveCardBackendHandlers`:** optional **`onRefresh`** wired to the same backend invoke path as **`Action.Execute`** (via **`ExecuteActionInvoke`** payload).
