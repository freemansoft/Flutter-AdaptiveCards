# Overlay test coverage

The status matrix for reactive-overlay test coverage, split out of the
`adaptive-cards-element-registry` SKILL so the skill body stays focused on
*implementing* an element. Consult this when adding a new overlay field or
deciding whether a specific `Input.*` / `Action.*` type needs a widget test.

> This is a point-in-time audit and drifts as tests are added. When it disagrees
> with the actual test tree, trust the code — and update the row you just proved
> stale.

Host-facing **patch keys by JSON `type`**: [`docs/overlay-properties-by-type.md`](../../../../docs/overlay-properties-by-type.md). **Programmatic lookup:** `CardTypeRegistry.overlayCapabilities` ([`overlay_capability_registry.dart`](../../../../packages/flutter_adaptive_cards_fs/lib/src/riverpod/overlay_capability_registry.dart)).

## Verdict

| Layer                                                               | Confidence                                                                                                                                                                                             |
| ------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Notifier + `resolvedElementProvider` / `resolvedActionProvider`** | High — [`adaptive_card_document_notifier_test.dart`](../../../../packages/flutter_adaptive_cards_fs/test/riverpod/adaptive_card_document_notifier_test.dart) covers most `AdaptiveCardDocumentNotifier` APIs |
| **Widget / host API per element or action type**                    | Partial — representative paths only; not every `Input.*` or `Action.*` has overlay-specific widget tests                                                                                               |

Overlay fields: [`adaptive_card_document.dart`](../../../../packages/flutter_adaptive_cards_fs/lib/src/riverpod/adaptive_card_document.dart). Merge: [`providers.dart`](../../../../packages/flutter_adaptive_cards_fs/lib/src/riverpod/providers.dart).

## Field-level notifier coverage

| Field                                  | Notifier | Example widget test                                               |
| -------------------------------------- | -------- | ----------------------------------------------------------------- |
| `isVisible`                            | Yes      | `visibility_overlay_test.dart`                                    |
| `inputValue`                           | Yes      | `text_overlay_test.dart`, …                                       |
| `choices` / query session              | Yes      | `choice_set_overlay_test.dart`, `choice_set_data_query_test.dart` |
| `errorMessage` / `isInvalid`           | Yes      | `text_overlay_test.dart`, …                                       |
| `text`, `url`, `facts`, `inlines`      | Yes      | See [by-type index](../../../../docs/overlay-properties-by-type.md)     |
| Chart extension payload                | Yes      | `chart_overlay_test.dart` (charts package)                        |
| Action `isEnabled`, `title`, `tooltip` | Yes      | `submit_overlay_test.dart`, …                                     |

Reactive wiring:

- **Elements:** `AdaptiveVisibilityMixin`, `AdaptiveInputMixin`, `AdaptiveTextBlock` → `resolvedElementProvider`
- **Actions:** `AdaptiveActionStateMixin` on [`icon_button.dart`](../../../../packages/flutter_adaptive_cards_fs/lib/src/cards/actions/icon_button.dart); [`show_card.dart`](../../../../packages/flutter_adaptive_cards_fs/lib/src/cards/actions/show_card.dart) watches `resolvedActionProvider` directly

## Cross-cutting

| Concern                                                                | Status                                                                          |
| ---------------------------------------------------------------------- | ------------------------------------------------------------------------------- |
| `resetAllInputs` preserves visibility, action overlays, TextBlock text | Notifier + ChoiceSet widget                                                     |
| `collectInputValues`                                                   | Notifier only                                                                   |
| Host APIs (`setText`, `setInputError`, `setActionEnabled`)             | Partial delegate tests in overlay test files                                    |
| Rebuild does not wipe overlays                                         | TextBlock + visibility widget tests; cached `_baselineMap` in `RawAdaptiveCard` |

## Gaps

Optional follow-up if tightening regressions:

1. Validation overlay widget tests for **Input.Date**, **Input.Time**
2. `Action.ResetInputs`, `Action.OpenUrlDialog`, `Action.InsertImage` overlay chrome
3. Rebuild survival with **input value** overlay (visibility and TextBlock covered)

## How to add tests for a new overlay field

1. **Notifier first** — extend [`adaptive_card_document_notifier_test.dart`](../../../../packages/flutter_adaptive_cards_fs/test/riverpod/adaptive_card_document_notifier_test.dart): `ProviderContainer` + `baselineMapProvider.overrideWithValue`, assert `overlaysById` and `resolvedElementProvider` / `resolvedActionProvider`.
2. **Widget test** — sample JSON under `test/samples/`, `getTestWidgetFromMap` / `getTestWidgetFromPath`, key-first finders per [`adaptive-cards-testing`](../../adaptive-cards-testing/SKILL.md).
3. **Host API** — if exposed on `RawAdaptiveCardState`, add a delegate test mirroring `setText` / `setInputError` patterns.
4. **Docs** — update [`docs/overlay-properties-by-type.md`](../../../../docs/overlay-properties-by-type.md) and [`overlay_capability_registry.dart`](../../../../packages/flutter_adaptive_cards_fs/lib/src/riverpod/overlay_capability_registry.dart).

Full test file catalog: [`adaptive-cards-testing` skill — Reactive document tests](../../adaptive-cards-testing/SKILL.md#reactive-document-tests-overlays-submit-reset).
