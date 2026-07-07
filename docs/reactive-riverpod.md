# Reactive Riverpod in `flutter_adaptive_cards_fs`

`flutter_adaptive_cards_fs` uses **Riverpod (v3.x)** internally as the reactive source of truth for:

- Card JSON (baseline) + runtime overlays (inputs, visibility, ChoiceSet choices, FactSet facts, TextBlock text, validation, action `isEnabled`)
- Per-card UI state (e.g. show-card expanded/collapsed)

This is intentionally **library-owned**: the package installs its own `ProviderScope` per rendered card subtree. Host apps do not need to depend on Riverpod directly unless they want to integrate with the library at a deeper level.

## Provider scopes

There are two nested scopes, matching the natural boundaries already present in the widget tree:

- **Raw card scope** (one per `RawAdaptiveCard`)
  - registries (`CardTypeRegistry`, `ActionTypeRegistry`) via `cardTypeRegistryProvider` / `actionTypeRegistryProvider`
  - `ReferenceResolver` via `styleReferenceResolverProvider` — **HostConfig + theme-aware values only** (not registries)
  - document notifier (baseline JSON + overlays)
- **Per-container style scope** (nested inside containers/columns via `ChildStyler`)
  - `styleReferenceResolverProvider` override with updated `inheritedContainerStyle` and `inheritedHorizontalAlignment`

See [Style inheritance data flow](adaptive-style.md#style-inheritance-data-flow).

- **Per-card-element scope** (one per `AdaptiveCardElement`)
  - show-card UI state for that card instance
  - optional nested document fork when rendering nested card subtrees
- **Width-bucket scope** (a thin nested scope inside each `AdaptiveCardElement`'s root `LayoutBuilder`)
  - `cardWidthBucketProvider` override with the current responsive [`WidthBucket`](../../packages/flutter_adaptive_cards_fs/lib/src/responsive/width_bucket.dart) derived from the card's measured width (`ReferenceResolver.resolveWidthBucket`)
  - kept **separate** from the element scope so layout passes only re-supply the bucket override; the element scope and the hoisted card subtree are not rebuilt, and `overrideWithValue` notifies watchers only when the bucket actually changes. See the responsive design doc, weakness W2: [`responsive-layout-targetwidth-flow-design.md`](superpowers/specs/2026-06-18-responsive-layout-targetwidth-flow-design.md).
  - read via `ref.watch(cardWidthBucketProvider)` by `AdaptiveVisibilityMixin` (`targetWidth` gating) and by `Container` / `Column` / `TableCell` / the card root body (`Layout.Flow` and `Layout.AreaGrid` selection via `buildLayoutChildren`); defaults to `WidthBucket.wide` (fail-open) when no scope is present.

```mermaid
flowchart TB
  subgraph rawCardScope [RawAdaptiveCard ProviderScope]
    doc[AdaptiveCardDocumentNotifier]
    reg[cardTypeRegistryProvider override]
    actions[actionTypeRegistryProvider override]
    resolver[styleReferenceResolverProvider override]
  end
  subgraph elementScope [AdaptiveCardElement ProviderScope]
    show[expandedShowCardIdProvider]
  end
  subgraph widthScope [LayoutBuilder nested ProviderScope]
    bucket[cardWidthBucketProvider override]
  end
  doc --> elem[Element widgets ref.watch by id]
  show --> showUi[ShowCard action + body slot]
  bucket --> respon[targetWidth visibility + Layout.Flow/AreaGrid selection]
```

## Document model: baseline + overlays

The document notifier stores:

- **Baseline JSON**: deep-copied map loaded from the host, stored as `_baselineMap` on `RawAdaptiveCardState` and passed to `baselineMapProvider` on each build (same instance until `widget.map` changes). This prevents host rebuilds from producing a new baseline reference every frame and wiping overlays.
- **Index**: `id -> baseline node` lookup for O(1) targeting.
- **Overlays**: sparse per-id runtime state (`ElementOverlay` + `ActionOverlay`; see [overlay properties by type](overlay-properties-by-type.md)).

Widgets render from a **resolved** view (baseline merged with overlays) via family providers like `resolvedElementProvider(id)`.

### Why overlays?

Runtime state like user input and visibility should not mutate the host’s map in place:

- makes reset semantics unclear
- causes aliasing if the host reuses a map instance
- makes reactive updates expensive (deep tree rebuilds)

Instead, overlays isolate runtime changes while keeping baseline patches (host/template refresh) possible.

## How overlays change values initialized from the adaptive map

### Two layers

| Layer        | Source                                                                           | Mutated at runtime? |
| ------------ | -------------------------------------------------------------------------------- | ------------------- |
| **Baseline** | Deep copy of host JSON (`baselineMapProvider` → `AdaptiveCardDocument.baseline`) | No                  |
| **Overlay**  | Sparse `overlaysById[id]` entries (`ElementOverlay`)                             | Yes                 |

Each overlay holds optional patches for that element id. **Which keys affect which JSON `type`** is indexed in [`overlay-properties-by-type.md`](overlay-properties-by-type.md). Patch key glossary and `applyUpdatesFromMap` field names are there; this doc covers architecture and behavior.

For an **input-only** architecture diagram (baseline, overlay fields, resolved view, submit, reset), see [`form-inputs.md` — Input overlay architecture](form-inputs.md#input-overlay-architecture).

Implementation: [`adaptive_card_document.dart`](../packages/flutter_adaptive_cards_fs/lib/src/riverpod/adaptive_card_document.dart), [`adaptive_card_document_notifier.dart`](../packages/flutter_adaptive_cards_fs/lib/src/riverpod/adaptive_card_document_notifier.dart).

### Initialization (first paint and initData)

Widgets read overlay-backed fields from **`resolvedElementProvider(id)`** via `watchResolvedInput()` in `build()` (inputs are `ConsumerStatefulWidget`s). Controllers and selection state remain local edit buffers. Host-provided [`initData`](../../packages/flutter_adaptive_cards_fs/README.md#loading-data-into-fields-outside-of-the-adaptivecard-json-with-initdata--initinput) is applied via `seedInputValues` on the document notifier (post-frame), not by walking the element tree.

#### Why `initInput` does not call `setState` on the card

Previously, `RawAdaptiveCardState.initInput` walked the element tree and each input’s `initInput(map)` called `setState` locally to update controllers and other widget state. That pushed data **into** each widget and made each widget responsible for its own rebuild.

The overlay model inverts that flow:

1. **`initInput` / `seedInputValues` only write overlays** — `RawAdaptiveCardState.initInput` delegates to `AdaptiveCardDocumentNotifier.seedInputValues`; per-input `initInput` overrides call `setDocumentInputValue`. Neither path calls `setState` on the card or input directly.
2. **Inputs watch resolved state in `build()`** — `AdaptiveInputMixin` uses `ref.watch(resolvedElementProvider(id))` for label, placeholder, `isRequired`, validation, and value display; `ref.listen` syncs controllers via `onDocumentValueChanged`. `AdaptiveVisibilityMixin`, `AdaptiveChoiceSet` (choices), and `AdaptiveTextBlock` still use `container.listen` in `didChangeDependencies` where not yet migrated.
3. **Overlay changes trigger rebuilds** — `ref.watch` / listeners update controllers and call `setState` where needed without walking the element tree.

So rebuilds still happen via `setState`; the call site moved from `initInput` to the resolved-element listener. That keeps one reactive path for `initData`, user typing, `ResetInputs`, and `ToggleVisibility` without tree walks.

```mermaid
flowchart LR
  initData[initData / initInput] --> seed[seedInputValues]
  seed --> overlay[inputValue overlay]
  overlay --> resolved[resolvedElementProvider id]
  resolved --> listener["ref.watch / ref.listen"]
  listener --> setState["onDocumentValueChanged + rebuild"]
```

**Timing:** `_AdaptiveCardDocumentLifecycle` seeds `initData` in a post-frame callback after inputs have mounted.

**When the UI may not update:** `initInput` is a no-op if `documentContainer` is not registered yet; or the id is not in `nodesById`.

### Runtime writes (user input, actions)

Changes go **only** into overlays via the document notifier:

| Action                            | Notifier API                                                                                                                                  | Overlay field                                                                                                                   |
| --------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------- |
| User edits an input               | `setInputValue(id, value)`                                                                                                                    | `inputValue`                                                                                                                    |
| Host initData / late binding      | `seedInputValues(map)` → `applyUpdates` (value only)                                                                                          | `inputValue` per id                                                                                                             |
| Bulk host / handler patches       | `applyUpdates` / `applyUpdatesFromMap`                                                                                                        | multiple fields per id                                                                                                          |
| Dynamic ChoiceSet options         | `setChoices(id, choices)` / `appendChoices(id, choices)`                                                                                      | `choices`                                                                                                                       |
| Typeahead pagination (optional)   | `setDataQuerySession(id, count:, skip:, searchText:)`                                                                                         | `queryCount`, `querySkip`, `querySearchText`                                                                                    |
| ToggleVisibility / set visibility | `setVisibility(id, visible: …)` / `toggleVisibility(id)`                                                                                      | `isVisible`                                                                                                                     |
| Host validation after submit      | `setInputError(id, errorMessage:, isInvalid:)` / `clearInputError(id)`                                                                        | `errorMessage`, `isInvalid`                                                                                                     |
| ResetInputs / per-id reset        | `resetAllInputs()` / `resetInput(id)` — see [Reset semantics](#reset-semantics)                                                               | factory reset on **`Input.*`**: clears value, choices, validation, **`isRequired`**, **`label`**, **`placeholder`** overlays    |
| Submit / Execute                  | `collectInputValues()` + validation via `validateInputs()`                                                                                    | reads overlay ?? baseline `"value"`; marks failing inputs with `setInputError(isInvalid: true)` (required + `Input.Text` regex) |
| Host loadInput API                | `RawAdaptiveCardState.loadInput(id, map)`                                                                                                     | delegates to `setChoices`                                                                                                       |
| Enable/disable actions            | `setActionEnabled(id, enabled:)` / `setActionsEnabled(map)`                                                                                   | `ActionOverlay.isEnabled`                                                                                                       |
| Password reveal toggle            | `setRevealPasswordEnabled(id, enabled)` / `clearRevealPasswordEnabled(id)`; `RawAdaptiveCardState` exposes the same names as facade           | `ElementOverlay.revealPasswordEnabled`; read via `ResolvedInputState.revealPasswordEnabledOverride`                             |
| Replace TextBlock text            | `setText(id, text)` / `clearText(id)`                                                                                                         | `text`                                                                                                                          |
| Replace FactSet facts             | `setFacts(id, facts)` / `clearFacts(id)` / `applyUpdates` (`facts` / `clearFacts` on `AdaptiveElementUpdate` or patch `{ clearFacts: true }`) | `facts`                                                                                                                         |
| Host helpers                      | `RawAdaptiveCardState.setInputError` / `setActionEnabled` / `setText` / `clearText` / `setFacts` / `clearFacts` / `applyUpdates`              | delegates to document notifier                                                                                                  |

The host’s map instance is never mutated in place.

### Reset semantics

`resetAllInputs()` and `resetInput(id)` apply the **same factory-reset policy**. Each affected `Input.*` id clears runtime overlays so **resolved fields match baseline JSON** for:

| Cleared to baseline    | Overlay fields                                   |
| ---------------------- | ------------------------------------------------ |
| Value & options        | `inputValue` → `value`, `choices` → `choices`    |
| Validation             | `errorMessage`, `isInvalid`                      |
| Dynamic input metadata | **`isRequired`**, **`label`**, **`placeholder`** |

**Preserved on that input id** (not part of “form values” reset):

| Preserved              | Overlay fields                               |
| ---------------------- | -------------------------------------------- |
| Visibility             | `isVisible`                                  |
| Typeahead session      | `queryCount`, `querySkip`, `querySearchText` |
| Password reveal toggle | `revealPasswordEnabled` (`Input.Text` only)  |

**Never modified** by input reset: TextBlock `text`, Image `url`, non-input visibility, **`actionOverlaysById`**, and the host baseline map.

#### Call paths

| API                                             | Scope                           | Typical caller                                                   |
| ----------------------------------------------- | ------------------------------- | ---------------------------------------------------------------- |
| `AdaptiveCardDocumentNotifier.resetAllInputs()` | All `Input.*` ids, one revision | `Action.ResetInputs` without `targetInputIds`, host code         |
| `AdaptiveCardDocumentNotifier.resetInputs(ids)` | Listed input ids, one revision  | `Action.ResetInputs` with `targetInputIds`, `valueChangedAction` |
| `AdaptiveCardDocumentNotifier.resetInput(id)`   | One input id                    | Host code; invoked from mixin `resetInput()`                     |

`AdaptiveInputMixin.resetInput()` should delegate to the notifier so overlay clear and UI stay in sync via `resolvedElementProvider(id)`. Subclass overrides sync controllers only — they must not be the sole reset path.

After reset, hosts can re-seed runtime state with `initInput`, `applyUpdates`, or `applyUpdatesFromMap`.

Spec: [`docs/superpowers/specs/2026-06-03-overlay-reset-semantics-design.md`](superpowers/specs/2026-06-03-overlay-reset-semantics-design.md). Targeted reset and `valueChangedAction`: [`2026-06-04-action-resetinputs-targetinputids-design.md`](superpowers/specs/2026-06-04-action-resetinputs-targetinputids-design.md).

### Resolved view (what widgets and actions read)

`resolvedElementProvider(id)` merges baseline node + overlay into a **new** map copy:

```dart
final merged = Map<String, dynamic>.from(baselineNode);
if (overlay?.isVisible != null) merged['isVisible'] = overlay!.isVisible;
if (overlay?.inputValue != null) merged['value'] = overlay!.inputValue;
if (overlay?.choices != null) merged['choices'] = overlay!.choices;
if (overlay?.errorMessage != null) merged['errorMessage'] = overlay!.errorMessage;
if (overlay?.isInvalid != null) merged['isInvalid'] = overlay!.isInvalid;
if (overlay?.text != null) merged['text'] = overlay!.text;
if (overlay?.facts != null) merged['facts'] = factsToJsonList(overlay!.facts!);
if (overlay?.isRequired != null) merged['isRequired'] = overlay!.isRequired;
if (overlay?.url != null) merged['url'] = overlay!.url;
// queryCount/querySkip merge into choices.data when present
```

`resolvedActionProvider(id)` merges baseline action node + `actionOverlaysById[id]` (returns `null` if the id is missing or not an `Action.*` type). Effective `isEnabled` is overlay value if set, else baseline (default enabled when absent).

Effective value rules:

- **Visibility**: overlay `isVisible` if set, else baseline `"isVisible"` (default `true`).
- **Input value**: overlay `inputValue` if set, else baseline `"value"`.
- **ChoiceSet choices**: overlay `choices` if set, else baseline `"choices"`.
- **TextBlock text**: overlay `text` if set, else baseline `"text"` (display still runs `parseTextString` / `DateTimeUtils.formatText` in the widget).
- **FactSet facts**: overlay `facts` if set (**replaces** entire baseline list), else baseline `"facts"`. `clearFacts` removes the overlay so baseline facts return.

### Keeping UI in sync

**Inputs** (`ConsumerStatefulWidget` + `AdaptiveInputMixin`): `watchResolvedInput()` at the start of `build()` for label, placeholder, `isRequired`, validation (`isInvalid` / `errorMessage`), and resolved value; `listenForResolvedValueChanges()` / `ref.listen` syncs controllers via `onDocumentValueChanged`. The post-frame callback reads the **latest** resolved value at execution time (via `readResolvedInput().valueRaw`) rather than the value captured when `ref.listen` fired — this makes the echo a no-op when the controller already reflects the current document state, preserving IME cursor position during fast typing. Form validators and `checkRequired` write validation via **`setLocalValidationError()`** / **`clearLocalValidationError()`** (notifier overlays). Error UI uses **`loadErrorMessage(..., showError: input.isInvalid)`** only.

`AdaptiveVisibilityMixin`, **`AdaptiveChoiceSet`** (dynamic `choices`), **`AdaptiveFactSet`** (dynamic `facts`), and **`AdaptiveTextBlock`** use `container.listen` on `resolvedElementProvider(id)` in `didChangeDependencies`. `AdaptiveActionStateMixin` and `Action.ShowCard` use `resolvedActionProvider(id)` for action overlays.

Input widgets call `setDocumentInputValue(...)` on user edits (which clears validation overlays). **`resetAllInputs()` / `resetInput(id)`** clear input overlays (including **`label`**, **`placeholder`**, **`isRequired`**) so resolved values fall back to baseline; see [Reset semantics](#reset-semantics).

```mermaid
flowchart TB
  hostMap[Host JSON map] --> deepCopy[baselineMapProvider deep copy]
  deepCopy --> index[nodesById index]
  deepCopy --> baselineNodes[Baseline nodes unchanged]

  userEdit[User input / ToggleVisibility] --> notifier[AdaptiveCardDocumentNotifier]
  notifier --> overlays[overlaysById sparse patches]

  baselineNodes --> merge[resolvedElementProvider id]
  overlays --> merge
  merge --> widgets[Inputs Visibility TextBlock FactSet ChoiceSet listen and rebuild]

  submit[Action.Submit] --> collect[collectInputValues overlay ?? baseline]
```

## Actions and inputs

- **ToggleVisibility**: see [Visibility (`isVisible`)](#visibility-isvisible) below.
- **ShowCard**: uses a card-local provider (`expandedShowCardIdProvider`) rather than widget identity.
- **Submit/Execute/ResetInputs**: collect/reset values from the document notifier rather than walking the Flutter element tree.

## Visibility (`isVisible`)

Visibility is driven by the document overlay model, not by mutating JSON or walking the widget tree:

- Baseline `"isVisible"` comes from the adaptive map at load time.
- Runtime changes (e.g. `Action.ToggleVisibility`) call `AdaptiveCardDocumentNotifier.setVisibility` / `toggleVisibility`, which write `ElementOverlay.isVisible`.
- `AdaptiveVisibilityMixin` listens to `resolvedElementProvider(id)` and rebuilds when the **merged** `isVisible` changes.
- Effective visibility is `isVisible` **AND** the element's `targetWidth` match: the mixin also `ref.watch`es `cardWidthBucketProvider` and ANDs in `targetWidthMatches(resolved['targetWidth'], bucket)`. These are independent gates — a runtime `setVisibility(true)` overlay cannot override a `targetWidth` miss, and vice-versa.

Other element overlays (e.g. **TextBlock** `text` via `setText`) use the same provider; see [How overlays change values](#how-overlays-change-values-initialized-from-the-adaptive-map).

### Widget implementation

- Elements with `AdaptiveVisibilityMixin` wrap content in a `Visibility` widget using the merged `isVisible` from `resolvedElementProvider(id)`.
- Baseline JSON may omit `isVisible` (defaults to visible) or set `"isVisible": false`.
- Host code can call `RawAdaptiveCardState.setIsVisible` or use `Action.ToggleVisibility`; both update the document notifier (`setVisibility` / `toggleVisibility`).

### Baseline `isVisible` values

| `adaptiveMap['isVisible']` | Effective visible |
| -------------------------- | ----------------- |
| `true` / omitted / null    | Visible           |
| `false`                    | Hidden            |

### Tests

Coverage lives in [`test/elements/visibility_overlay_test.dart`](../packages/flutter_adaptive_cards_fs/test/elements/visibility_overlay_test.dart):

- JSON `isVisible` on elements
- `RawAdaptiveCardState.setIsVisible` and notifier `toggleVisibility`
- `Action.ToggleVisibility`
- Visibility overlay survives `RawAdaptiveCard.rebuild()`

See [Overlay test coverage](#overlay-test-coverage) and [`overlay-properties-by-type.md`](overlay-properties-by-type.md).

## Host callbacks

Host callbacks (`onSubmit`, `onExecute`, `onRefresh`, `onOpenUrl`, `onOpenUrlDialog`, `onChange`, `onHttp`, …) remain on **`InheritedAdaptiveCardHandlers`**. These are host integration points, not reactive document state. Each callback receives a typed invoke payload: **`SubmitActionInvoke`**, **`ExecuteActionInvoke`**, **`RefreshActionInvoke`**, **`OpenUrlActionInvoke`**, **`OpenUrlDialogActionInvoke`**, **`InputChangeInvoke`**, or **`HttpActionInvoke`** (the nullable `onHttp` handles the deprecated/legacy `Action.Http` — original Adaptive Cards HTTP action model superseded by `Action.Execute` in schema v1.4, still used by Outlook Actionable Messages; the core forwards a resolved request and never performs it). **`AdaptiveCardsCanvas.onChange`** accepts **`InputChangeInvoke`** directly.

When a ChoiceSet with `choices.data` fires `onChange`, **`InputChangeInvoke.dataQuery`** includes sibling input values in **`parameters`** when `associatedInputs` is **`"auto"`** (default when omitted). The firing input id is excluded; set **`"none"`** to pass JSON `parameters` only. See [Dependent ChoiceSet](form-inputs.md#dependent-choiceset-country--city).

## Server-driven patches (host package)

When using optional **`flutter_adaptive_cards_host_fs`**, backend responses apply overlays automatically — you usually **do not** hand-write `applyUpdates` in `onSubmit`/`onChange` unless customizing behavior.

| Response effect  | Core API                                               | Overlay fields                                                                       |
| ---------------- | ------------------------------------------------------ | ------------------------------------------------------------------------------------ |
| `applyPatches`   | `RawAdaptiveCardState.applyUpdates(elements: …)`       | `choices`, `inputValue`, `isVisible`, `text`, `facts`, … per `AdaptiveElementUpdate` |
| `setInputErrors` | `applyUpdates` with `errorMessage` + `isInvalid: true` | `errorMessage`, `isInvalid` on each input id                                         |
| `replaceCard`    | Host **`onCardReplaced`** callback                     | Replaces baseline JSON; overlays re-seed from new map                                |

**Apply order:** patches → input errors → full card replacement (see [backend-invoke-reference.md](backend-invoke-reference.md#effect-types-and-apply-order)).

Manual **`onSubmit` validation** (without the host package) still uses the same overlay fields — see [Host-driven validation](form-inputs.md#host-driven-validation-and-bulk-updates).

Tests: `packages/flutter_adaptive_cards_host_fs/test/handlers/backend_handlers_test.dart`; core patch merge in `test/riverpod/apply_updates_test.dart`.

## Overlay test coverage

Per-type patch keys and contract tests: [`overlay-properties-by-type.md`](overlay-properties-by-type.md). Programmatic lookup: `CardTypeRegistry.overlayCapabilities` (`OverlayCapabilityRegistry`).

| Layer                      | Confidence                                                       |
| -------------------------- | ---------------------------------------------------------------- |
| Notifier + merge providers | High — `test/riverpod/adaptive_card_document_notifier_test.dart` |
| Widget tests per type      | Partial — representative `*_overlay_test.dart` files only        |

Adding a new overlay field requires notifier tests plus a widget test for each consuming type. Implementer checklist: [adaptive-cards-element-registry skill](../.agents/skills/adaptive-cards-element-registry/SKILL.md#overlay-test-coverage).

### How to add tests

1. **Notifier** — `ProviderContainer` with `baselineMapProvider.overrideWithValue(...)`, assert `resolvedElementProvider` / `resolvedActionProvider` and `overlaysById`.
2. **Widget** — extend the type's `*_overlay_test.dart`; see [adaptive-cards-testing skill](../.agents/skills/adaptive-cards-testing/SKILL.md#reactive-document-tests-overlays-submit-reset).
3. **Host API** — delegate tests on `RawAdaptiveCardState` when exposing new helpers.

Regression:

```bash
cd packages/flutter_adaptive_cards_fs
fvm flutter test test/riverpod/adaptive_card_document_notifier_test.dart
fvm flutter test $(find test -name '*_overlay_test.dart')
```

## Overlay backlog

Future overlays and gaps not in [`overlay-properties-by-type.md`](overlay-properties-by-type.md): `Action.iconUrl`; ChoiceSet `choices.data.parameters` binding. New work should follow existing patterns (`ElementOverlay` / `ActionOverlay`, merge in `resolved*Provider`, widget listeners, tests, update the by-type index).
