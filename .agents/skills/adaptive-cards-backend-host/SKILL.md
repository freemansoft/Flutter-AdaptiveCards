---
name: adaptive-cards-backend-host
description: >
  Optional flutter_adaptive_cards_host_fs package — backend invoke serialization,
  PlainJson/Teams adapters, AdaptiveCardBackendHandlers, and response effects.
  Use when wiring Submit/Execute/Refresh/onChange to a flow-service or reviewing
  associatedInputs + invoke round-trips.
---

# Backend Host Integration Skill

Optional package: **`packages/flutter_adaptive_cards_host_fs`**

- **Depends on:** `flutter_adaptive_cards_fs`, `http`
- **Published:** Yes — [pub.dev](https://pub.dev/packages/flutter_adaptive_cards_host_fs) (barrel: `lib/flutter_adaptive_cards_host_fs.dart`)
- **Docs:** [docs/backend-host-integration.md](../../../docs/backend-host-integration.md)
- **Design history:** [docs/archive/specs/2026-06-07-backend-host-integration-design.md](../../../docs/archive/specs/2026-06-07-backend-host-integration-design.md)

## When to use

| Scenario | Package |
| -------- | ------- |
| Render cards; hand-wire `InheritedAdaptiveCardHandlers` | Core only |
| Teams-correct invoke payloads (`associatedInputs`) | Core (always) |
| Serialize → POST → parse → `applyTo` automatically | **`flutter_adaptive_cards_host_fs`** |

## Key types

- **`AdaptiveCardBackendHandlers`** — wraps card subtree; wires `onSubmit`, `onExecute`, `onRefresh`, `onChange`
- **`AdaptiveCardBackendClient`** / **`HttpAdaptiveCardBackendClient`** — transport
- **`PlainJsonInvokeAdapter`** / **`TeamsInvokeAdapter`** — request/response JSON shapes
- **`AdaptiveCardInvokeResponse.applyTo`** — `applyPatches`, `setInputErrors`, `replaceCard` (via `onCardReplaced`)

Requires shared **`GlobalKey<RawAdaptiveCardState>`** on handlers and `RawAdaptiveCard` (except `onChange`, which uses `invoke.cardState`).

## Tests

No golden tests. Run from package directory:

```bash
cd packages/flutter_adaptive_cards_host_fs
fvm flutter test
```

Primary files:

- `test/handlers/backend_handlers_test.dart`
- `test/adapters/plain_json_invoke_adapter_test.dart`
- `test/adapters/teams_invoke_adapter_test.dart`
- `test/client/http_backend_client_test.dart`

Core **`associatedInputs`** tests remain in `packages/flutter_adaptive_cards_fs/test/utils/associated_inputs_test.dart` and related input tests.

## Related skills

- **`adaptive-cards-monorepo-workspace`** — workspace layout and `fvm` working directories
- **`adaptive-cards-testing`** — core widget/notifier test patterns
- **`release-engineer`** — sync `version:` and `flutter_adaptive_cards_fs: ^<version>` on post-release bump
