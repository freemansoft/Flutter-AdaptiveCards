---
name: code-review
description: >
  Quality gate and checklist for reviewing changes in the Flutter-AdaptiveCards monorepo.
  Covers monorepo hygiene, AC spec compliance, theming, keys, accessibility, and testing.
  Use this for both manual and AI-assisted final reviews before proposing changes.
---

# Code Review Protocol

Use this skill as a "Final Gate" for any PR or significant change. Cross-reference with specialized skills (`adaptive-cards-spec-compliance`, `adaptive-cards-element-registry`, `dart-public-api-docs`, `flutter-adaptive-cards-testing`) as needed.

---

## 1. Monorepo Hygiene & Consistency

- [ ] **FVM usage**: Are all commands (`flutter`, `dart`) executed via `fvm`?
- [ ] **Analysis**: Does the code pass `fvm flutter analyze`? (Compliance with `very_good_analysis`).
- [ ] **Changelog**: Has `CHANGELOG.md` been updated in the affected packages following [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)?
- [ ] **Release / post-publish** (if applicable): Follow `release-engineer` — all **six** `version:` fields match, **six** changelogs have matching top `## [<version>]` sections, and `flutter_adaptive_charts_fs` and `flutter_adaptive_cards_host_fs` use `flutter_adaptive_cards_fs: ^<version>`.
- [ ] **Formatting**: Has `dart_format` been run on all modified files?
- [ ] **Public `///` docs**: Do exported API changes in library packages explain why and how to use the API (not implementation steps)? See **`dart-public-api-docs`**.

### Documentation impact (canonical `docs/`)

Architecture docs drift silently. If this change touches any of the triggers below, `git grep` the affected symbols in `docs/` and confirm the canonical docs were updated **in this change** (see the "Architecture documentation sync gate" in `AGENTS.md`).

- [ ] **Providers / scopes**: Did it add/remove/rename a Riverpod provider or `ProviderScope` (including nested scopes), or move a provider between scopes? → Update [`docs/reactive-riverpod.md`](../../docs/reactive-riverpod.md) (provider scopes + diagram) and [`docs/Architecture-Overview.md`](../../docs/Architecture-Overview.md) (scope diagram).
- [ ] **Mixin contracts**: Did it change what a mixin watches or how effective state is computed (e.g. `AdaptiveVisibilityMixin.isVisible`, `AdaptiveInputMixin`)? → Update the relevant section of [`docs/reactive-riverpod.md`](../../docs/reactive-riverpod.md).
- [ ] **HostConfig / element contracts**: Did it add/remove/rename a HostConfig section, element/action type, or overlay field? → Update [`docs/hostconfig.md`](../../docs/hostconfig.md), [`docs/Implementation-Status.md`](../../docs/Implementation-Status.md), and [`docs/overlay-properties-by-type.md`](../../docs/overlay-properties-by-type.md) as applicable.
- [ ] **No stale references**: `git grep -n '<removed-or-renamed-symbol>' docs/` returns nothing pointing at deleted/renamed code (a stale doc reference is a blocker, not a nit).

---

## 2. `flutter_adaptive_cards_fs` Checklist

### Registration & Pattern Compliance

- [ ] **Registry**: Is the new element/action added to `CardTypeRegistry` or `ActionTypeRegistry`?
- [ ] **Mixins**: Does the element correctly implement `AdaptiveElementWidgetMixin` (Widget) and `AdaptiveElementMixin` + `AdaptiveVisibilityMixin` (State)?
- [ ] **Inputs**: Does the input use `AdaptiveInputMixin`? On user change, does it call `setDocumentInputValue(...)`? Does it sync controllers in `onDocumentValueChanged` when overlays change (reset)?
- [ ] **Visibility**: If visibility can change at runtime, does the element use `AdaptiveVisibilityMixin` and write via `setIsVisible` / document notifier (not local-only `setState`)?
- [ ] **TextBlock text**: If runtime text can change, does `AdaptiveTextBlock` read display copy from `resolvedElementProvider(id)` (not only stale `adaptiveMap['text']`)?
- [ ] **Actions**: Do action buttons respect `isEnabled` via `AdaptiveActionStateMixin` / `resolvedActionProvider` when host-driven enable/disable matters?
- [ ] **Overlays**: Are host/runtime patches written through the document notifier (`setInputValue`, `setText`, `setInputError`, …) rather than mutating the host JSON map?
- [ ] **Extension boundary**: Does `flutter_adaptive_cards_fs` avoid chart-specific (or other optional-package) types, imports, and overlay fields? Optional behavior belongs in extension packages via `addedElements` / `overlayExtensions`, not in core.

### Theming & Styling

- [ ] **ReferenceResolver**: Does the element use `styleResolver` (via `ProviderScopeMixin`) or `ProviderScope.containerOf(context).read(styleReferenceResolverProvider)` for all colors, font sizes, and spacing?
- [ ] **Registries**: Does the element use `cardTypeRegistry` / `actionTypeRegistry` from `ProviderScopeMixin` (not from `ReferenceResolver`)?
- [ ] **Theme Awareness**: Has it been verified in both **Light** and **Dark** modes?
- [ ] **HostConfig**: Does it respect spacing, separator, and padding properties from JSON via `SeparatorElement`?

### Keys & Identity

- [ ] **Deterministic Keys**: Is the outer widget key generated via `generateAdaptiveWidgetKey(adaptiveMap)`?
- [ ] **Internal Keys**: For inputs or sub-elements, are keys generated using the `id` (e.g., `ValueKey(id)` or `ValueKey('${id}_suffix')`)? _Crucial for testing stability._

### Accessibility

- [ ] **Semantics**: Does the widget use `Semantics` or `semanticLabel` where appropriate?
- [ ] **Alt-text**: For images or icons, is the `altText` (if provided in JSON) used as a semantic label?

### Exports

- [ ] **Public API**: Is the new class/widget exported in `lib/flutter_adaptive_cards_fs.dart`?
- [ ] **Extension API**: Is it exported in `lib/flutter_adaptive_cards_extend.dart` if intended for customization by consumers?
- [ ] **Public `///` docs**: Do new or changed exported members explain **why** the API exists and **how** callers use it — not implementation steps? See **`dart-public-api-docs`**.

---

## 3. `flutter_adaptive_template_fs` Checklist

- [ ] **Expression Evaluation**: Are new AST nodes or functions implemented in both the parser and the evaluator?
- [ ] **Reserved Keywords**: Are `$data`, `$root`, `$index`, and `$when` handled correctly during expansion?
- [ ] **Scope Integrity**: Does nesting `$data` correctly shift the resolution context?

---

## 4. `flutter_adaptive_cards_host_fs` Checklist

- [ ] **Handlers**: `AdaptiveCardBackendHandlers` shares the same `GlobalKey<RawAdaptiveCardState>` as `RawAdaptiveCard` when `onSubmit` / `onExecute` / `onRefresh` need card state.
- [ ] **Adapters**: PlainJson vs Teams invoke shapes match the backend contract; response effects applied via `AdaptiveCardInvokeResponse.applyTo`.
- [ ] **Dependencies**: `pubspec.yaml` declares `flutter_adaptive_cards_fs: ^<monorepo-version>` (sync on release bump).
- [ ] **Tests**: Unit tests under `packages/flutter_adaptive_cards_host_fs/test/` (no goldens); run `fvm flutter test` from that package directory.
- [ ] **Docs**: Public API changes reflected in `docs/backend-host-integration.md` and package `README.md`; exported `///` comments follow **`dart-public-api-docs`**.

See **`adaptive-cards-backend-host`** skill for file paths and invoke round-trip patterns.

---

## 5. Testing Protocol

- [ ] **Key-First Searching**: All `find.text()` or `find.byType()` calls in tests should be replaced with `find.byKey()` whenever a key is available.
- [ ] **JSON Samples**: Is there a new file in `test/samples/` demonstrating the feature/fix?
- [ ] **Golden Tests**:
  - Have golden tests been added/updated for UI changes?
  - **New goldens:** generate with `--update-goldens` on macOS, then **copy each new PNG from `test/gold_files/macos/` to `test/gold_files/linux/`** so CI has a baseline (see `adaptive-cards-testing` skill and `test/gold_files/README.md`).
  - **CI pixel failures:** replace `linux/` files from CI artifact zips for canonical Linux images.

### `widgetbook` changes (sample app)

- [ ] **Asset registration**: New folders under `widgetbook/lib/samples/` are listed in `widgetbook/pubspec.yaml` under `flutter: assets:` (required for `AdaptiveCardsCanvas.asset`).
- [ ] **Use case / codegen**: `@widgetbook.UseCase` added or updated in `adaptive_cards_use_cases.dart`; `fvm dart run build_runner build` run when use cases change.
- [ ] **Changelog**: `widgetbook/CHANGELOG.md` updated when the demo app changes.
- [ ] **Docs**: Overlay knob pages → registry row in [`docs/widgetbook-overlay-demos.md`](../../docs/widgetbook-overlay-demos.md); package behavior docs tag widgetbook as **Example (widgetbook sample)** per [`documentation-scope.md`](../../docs/documentation-scope.md).

---

## Review Output Template

When performing a review, summarize findings using this format:

```markdown
### Code Review Summary

- **Package**: [e.g. flutter_adaptive_cards_fs]
- **Hygiene**: [PASS/FAIL] (Analysis, Changelog, Formatting)
- **Docs impact**: [PASS/FAIL/N-A] (canonical `docs/` synced; no stale references)
- **Compliance**: [PASS/FAIL] (Registry, Spec, Theming)
- **Testing**: [PASS/FAIL] (Keys, Samples, Goldens)

#### Details

- [Specific feedback regarding keys, accessibility, etc.]
```
