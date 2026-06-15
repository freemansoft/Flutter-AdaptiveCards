---
name: Reactive Riverpod in flutter_adaptive_cards_fs
overview: Reintroduce Riverpod into `packages/flutter_adaptive_cards_fs` as the reactive source of truth for card document + per-element runtime state (visibility, inputs, show-card UI), replacing imperative element-tree walks and widget registries. Update `AGENTS.md` and docs to endorse this architecture.
todos:
  - id: build-green-first
    content: Add flutter_riverpod to flutter_adaptive_cards_fs and ensure fvm flutter analyze is clean
    status: completed
  - id: policy-docs
    content: Update AGENTS.md and docs (replace-riverpod.md, Architecture-Overview.md) to endorse Riverpod; add doc/reactive-riverpod.md
    status: completed
  - id: riverpod-scopes
    content: Introduce ProviderScope per RawAdaptiveCard and per AdaptiveCardElement with provider overrides for registries/resolver/document
    status: completed
  - id: document-notifier
    content: Implement AdaptiveCardDocumentNotifier (baseline JSON + id index + overlays) and resolvedElement family provider
    status: completed
  - id: toggle-visibility
    content: Migrate ToggleVisibility to notifier writes + element visibility watches; delete RawAdaptiveCardState tree-walk visibility methods
    status: completed
  - id: show-card
    content: Migrate ShowCard to expandedShowCardId provider; remove currentCard widget identity toggling and _registeredCards / registerCardWidget paths
    status: completed
  - id: form-actions
    content: Migrate Submit/Execute/ResetInputs to read/write input overlay state instead of visitChildElements
    status: completed
  - id: element-migration
    content: Convert element/input/action states to ConsumerState (or ConsumerWidget) and remove InheritedReferenceResolver/ProviderScopeMixin usage
    status: completed
  - id: tests
    content: Update/add tests for reactive visibility, show-card, and submit/reset behavior; adjust/remove inherited scope tests
    status: completed
isProject: false
---

# Reactive Riverpod migration plan (flutter_adaptive_cards_fs)

## Goal

Update [`packages/flutter_adaptive_cards_fs`](packages/flutter_adaptive_cards_fs) to use **Riverpod reactively** (not just DI), so:

- **Visibility** updates (e.g. `Action.ToggleVisibility`) no longer require walking the Flutter element tree.
- **ShowCard** expand/collapse no longer relies on widget identity or `_registeredCards`.
- **Inputs** become a document-backed reactive state source (submit/reset read from the document, not `visitChildElements`).
- Library-owned scopes preserve current host ergonomics (hosts shouldn’t need to add an app-level `ProviderScope`).

This plan uses the archived template at [`2026-05-31-reactive_riverpod_in_library_2c717ed6.plan.md`](../archive/plans/2026-05-31-reactive_riverpod_in_library_2c717ed6.plan.md) as the architectural baseline, but tailors it to *this repo’s current* imperative state flows.

## Current state (what we’re replacing)

The current reactive behaviors in `flutter_adaptive_cards_fs` are imperative and scoped via `InheritedWidget`:

- **DI / scoping**: `InheritedReferenceResolver` (outer raw-card scope + inner per-`AdaptiveCardElement` scope) ([`packages/flutter_adaptive_cards_fs/lib/src/inherited_reference_resolver.dart`](packages/flutter_adaptive_cards_fs/lib/src/inherited_reference_resolver.dart)); used via `ProviderScopeMixin` ([`packages/flutter_adaptive_cards_fs/lib/src/adaptive_mixins.dart`](packages/flutter_adaptive_cards_fs/lib/src/adaptive_mixins.dart)).
- **Visibility**: `RawAdaptiveCardState.toggleVisibility` walks the element tree and calls `AdaptiveVisibilityMixin.setIsVisible` ([`packages/flutter_adaptive_cards_fs/lib/src/flutter_raw_adaptive_card.dart`](packages/flutter_adaptive_cards_fs/lib/src/flutter_raw_adaptive_card.dart)).
- **Submit/Execute/ResetInputs**: `DefaultSubmitAction` / `DefaultExecuteAction` / `DefaultResetInputsAction` traverse elements and read `AdaptiveInputMixin` ([`packages/flutter_adaptive_cards_fs/lib/src/action/default_actions.dart`](packages/flutter_adaptive_cards_fs/lib/src/action/default_actions.dart)).
- **ShowCard**:
  - `AdaptiveCardElementState` stores `currentCard` and toggles with `setState` ([`packages/flutter_adaptive_cards_fs/lib/src/cards/adaptive_card_element.dart`](packages/flutter_adaptive_cards_fs/lib/src/cards/adaptive_card_element.dart)).
  - `AdaptiveActionShowCardState` builds a `targetCard` widget and toggles based on `adaptiveCardElementState.currentCard != targetCard` (identity-based) ([`packages/flutter_adaptive_cards_fs/lib/src/cards/actions/show_card.dart`](packages/flutter_adaptive_cards_fs/lib/src/cards/actions/show_card.dart)).
  - There is also an unused/legacy per-card `_registeredCards` map in `AdaptiveCardElementState` that is still written to via `AdaptiveElementMixin.didChangeDependencies` ([`packages/flutter_adaptive_cards_fs/lib/src/adaptive_mixins.dart`](packages/flutter_adaptive_cards_fs/lib/src/adaptive_mixins.dart)).

Docs currently assert “Riverpod removal completed” ([`doc/replace-riverpod.md`](doc/replace-riverpod.md)) and `AGENTS.md` explicitly discourages Riverpod in `flutter_adaptive_cards_fs` ([`AGENTS.md`](AGENTS.md)). Those will be reversed.

## Target architecture

### Provider scopes

Mirror existing *two-scope* structure (raw-card vs per-card-element), but implement with Riverpod scopes instead of `InheritedReferenceResolver`:

- **Raw card scope** (one per `RawAdaptiveCard`):
  - Owns the **document notifier** (baseline JSON + overlays).
  - Owns registry + resolver providers (type registries, `ReferenceResolver`).
- **AdaptiveCardElement scope** (one per nested `AdaptiveCardElement`):
  - Owns **show-card UI state** for that card instance (expanded target id).
  - Optionally owns a forked document notifier when rendering nested card subtrees (recommended for isolation).

### Document model (baseline + runtime overlay)

Adopt the template’s “baseline + overlay” approach:

- **Baseline**: deep-copied card JSON map supplied by the host (so we never mutate the host’s map instance in-place).
- **Index**: map of `id -> node` built once per baseline (enables O(1) lookup for actions like ToggleVisibility).
- **Overlays** (sparse): per-id runtime state such as:
  - `isVisible` overrides
  - `inputValue` overrides

Element widgets read a **resolved element map** via a family provider, which merges baseline node + overlay into a safe copy.

### Reactive actions

- `Action.ToggleVisibility`: writes to document notifier (`toggleVisibility(id)`) rather than walking Flutter elements.
- `Action.Submit` / `Action.Execute` / `Action.ResetInputs`: read/write from document notifier overlay tables (inputs), rather than `visitChildElements`.
- `Action.ShowCard`: manage expanded show-card target via a per-`AdaptiveCardElement` `Notifier` keyed by target id (no widget identity, no `_registeredCards`).

## Incremental migration strategy (keep build green)

The safest path is to *introduce Riverpod alongside* the inherited scopes first, then migrate features, then delete old paths.

### Phase 0: Build green gate

- Add `flutter_riverpod` dependency (target **3.2.1**) to [`packages/flutter_adaptive_cards_fs/pubspec.yaml`](packages/flutter_adaptive_cards_fs/pubspec.yaml).
- Ensure `fvm flutter analyze` is clean for that package.

### Phase 1: Provider scaffolding (no behavior changes yet)

- Create a new internal module, e.g. `lib/src/riverpod/`:
  - `adaptive_card_document.dart` (immutable state types)
  - `adaptive_card_document_notifier.dart`
  - `providers.dart` (provider declarations + family providers)
  - `show_card_ui_notifier.dart` (per-card expanded id)
- Wrap the `RawAdaptiveCard` subtree in a `ProviderScope` and install overrides for:
  - `cardTypeRegistryProvider` (from widget param)
  - `actionTypeRegistryProvider` (from widget param)
  - `styleReferenceResolverProvider` (built from `HostConfigs` + registries; mirrors `_updateResolver()`)
  - `adaptiveCardDocumentProvider` (seeded from `widget.map` deep copy)

Implementation entry points:
- [`packages/flutter_adaptive_cards_fs/lib/src/flutter_raw_adaptive_card.dart`](packages/flutter_adaptive_cards_fs/lib/src/flutter_raw_adaptive_card.dart): add `ProviderScope` and initialize document.

At this stage, existing widgets can continue to use `InheritedReferenceResolver` + `ProviderScopeMixin` unchanged.

### Phase 2: ToggleVisibility migration (first reactive win)

- Replace `RawAdaptiveCardState.toggleVisibility` / `setIsVisible` usage with notifier writes.
  - Current tree-walk methods in `RawAdaptiveCardState` are at lines ~155–225 in [`flutter_raw_adaptive_card.dart`](packages/flutter_adaptive_cards_fs/lib/src/flutter_raw_adaptive_card.dart).
- Update `DefaultToggleVisibilityAction` in [`packages/flutter_adaptive_cards_fs/lib/src/action/default_actions.dart`](packages/flutter_adaptive_cards_fs/lib/src/action/default_actions.dart) to call:
  - `ref.read(adaptiveCardDocumentProvider.notifier).toggleVisibility(elementId)`
  - This implies default actions must have a way to obtain `WidgetRef`/`Ref` (options below).

**How actions get `ref`** (pick one and standardize):
- **Option A (recommended)**: make action widgets (like `AdaptiveActionToggleVisibility`) become `ConsumerStatefulWidget` and call notifier directly from the widget, bypassing `Default*Action` needing `ref`.
- **Option B**: introduce a small inherited adapter `InheritedWidgetRef` installed near `ProviderScope` that exposes `Ref` to non-consumer code.
- **Option C**: store a document controller on `RawAdaptiveCardState` (created in build via a `Consumer`) and keep default actions calling through `rawAdaptiveCardState`.

(Option A yields the cleanest Riverpod-first architecture and avoids passing `ref` through imperative layers.)

- Convert `AdaptiveVisibilityMixin`-using elements to read their visibility from `resolvedElementProvider(id)` (instead of owning `isVisible` state + `setState`).

### Phase 3: ShowCard migration (remove identity toggling)

- Replace `AdaptiveCardElementState.currentCard` + `showCard(AdaptiveCardElement card)` with a per-element-scope provider:
  - `expandedShowCardIdProvider` (string? id)
  - `toggleShowCard(targetId)`
- Update [`packages/flutter_adaptive_cards_fs/lib/src/cards/actions/show_card.dart`](packages/flutter_adaptive_cards_fs/lib/src/cards/actions/show_card.dart) to:
  - compute a stable `targetCardId` (from the nested card map; if missing, generate a deterministic synthetic id based on action id + index/path)
  - write `expandedShowCardId`
  - render chevron state based on watched expanded id
- Update [`packages/flutter_adaptive_cards_fs/lib/src/cards/adaptive_card_element.dart`](packages/flutter_adaptive_cards_fs/lib/src/cards/adaptive_card_element.dart) to:
  - conditionally render the nested card body when `expandedShowCardId == targetCardId`
  - stop storing `currentCard` as a widget

Remove dead/legacy registry paths:
- Delete `_registeredCards` from `AdaptiveCardElementState` and the `registerCardWidget`/`unregisterCardWidget` methods.
- Remove registration calls in `AdaptiveElementMixin.didChangeDependencies` and `dispose` in [`packages/flutter_adaptive_cards_fs/lib/src/adaptive_mixins.dart`](packages/flutter_adaptive_cards_fs/lib/src/adaptive_mixins.dart).

### Phase 4: Inputs + submit/reset reactive collection

- Introduce overlay-backed input APIs in the document notifier:
  - `setInputValue(id, value)`
  - `resetAllInputs()` and/or `resetInputs(Set<String> ids)`
  - `collectSubmitData(scope)` (raw card vs current `AdaptiveCardElement`)
- Migrate input widgets (`Input.Text`, `Input.Toggle`, etc.) to:
  - write values to notifier
  - watch resolved value to update UI
- Update default actions in [`packages/flutter_adaptive_cards_fs/lib/src/action/default_actions.dart`](packages/flutter_adaptive_cards_fs/lib/src/action/default_actions.dart) so `Submit`/`Execute` use notifier data rather than traversing widgets.

### Phase 5: Replace `InheritedReferenceResolver` / `ProviderScopeMixin`

Once major behaviors are Riverpod-driven:

- Convert `ProviderScopeMixin` into a Riverpod-friendly mixin (or remove it):
  - replace `rawRootCardWidgetState`, registry access, `styleResolver` to use providers.
- Remove `InheritedReferenceResolver` from:
  - `RawAdaptiveCard` build (outer scope)
  - `AdaptiveCardElement` build (inner scope)
- Keep `InheritedAdaptiveCardHandlers` for host callbacks (that’s not state and doesn’t need Riverpod).

## API/semver and dependency impact

- Reintroducing `flutter_riverpod` makes it a **transitive dependency** for consumers of `flutter_adaptive_cards_fs` (the package previously removed it in `0.8.0`; see [`packages/flutter_adaptive_cards_fs/CHANGELOG.md`](packages/flutter_adaptive_cards_fs/CHANGELOG.md)).
- Treat as **major version** unless the repo’s release policy dictates otherwise.

## Documentation updates (policy reversal)

Update docs to explicitly endorse Riverpod in this package:

- [`AGENTS.md`](AGENTS.md)
  - Replace the “Do not add Riverpod…” line with guidance that **Riverpod is the preferred reactive state mechanism** for `flutter_adaptive_cards_fs`.
- [`doc/replace-riverpod.md`](doc/replace-riverpod.md)
  - Rewrite from “removal completed” to a historical note + new Riverpod architecture summary (or supersede with a new doc and keep this as history).
- [`doc/Architecture-Overview.md`](doc/Architecture-Overview.md)
  - Update “State and dependency injection” section to Riverpod scopes + notifier-driven state.
- Add a new doc (recommended): `doc/reactive-riverpod.md`
  - Provider scope diagram
  - Document model (baseline + overlays)
  - Migration notes for custom registries and host callbacks

## Tests and rollout

- Update widget tests that assert inherited-scope behavior (e.g. [`packages/flutter_adaptive_cards_fs/test/inherited_reference_resolver_test.dart`](packages/flutter_adaptive_cards_fs/test/inherited_reference_resolver_test.dart)):
  - either replace with provider-scope tests, or keep minimal tests while inherited scopes still exist (Phase 1–4).
- Add targeted tests for:
  - ToggleVisibility updates UI without tree walk
  - ShowCard expanded id toggling is stable across rebuilds
  - Submit collects overlay-backed values correctly

## Success criteria

- `Action.ToggleVisibility` updates visibility via notifier + `ref.watch` (no `visitChildElements` / tree walk).
- `Action.ShowCard` is id-driven (no widget identity comparisons, no `_registeredCards`).
- Submit/Execute/ResetInputs do not traverse the widget tree to gather input values.
- Library wraps its own `ProviderScope` so host ergonomics remain similar.
- Documentation explicitly endorses Riverpod usage within `flutter_adaptive_cards_fs`.
