# Changelog

## [0.13.0]

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
