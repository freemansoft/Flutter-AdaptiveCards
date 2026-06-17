# Changelog

## [0.11.0]

- no changes yet

## [0.10.0]

- Initial release: `AdaptiveCardInvokeRequest`, PlainJson and Teams adapters, `AdaptiveCardInvokeResponse` with `applyTo`, `HttpAdaptiveCardBackendClient`, and `AdaptiveCardBackendHandlers`.
- **`AdaptiveCardBackendHandlers`:** optional **`onRefresh`** wired to the same backend invoke path as **`Action.Execute`** (via **`ExecuteActionInvoke`** payload).
