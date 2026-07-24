# Accessibility & Key-Generation Review — `flutter_adaptive_cards_fs`

**Date:** 2026-07-01
**Status last verified:** 2026-07-02 (against `main` @ `f06d7ab`)
**Scope:** `packages/flutter_adaptive_cards_fs/lib/`
**Status:**

- **Implemented (branch `fix/adaptive-tappable-deterministic-keys`, merged PR #4):** #1, #2, #8 + key-helper centralization.
- **Implemented (branch `fix/accessibility-semantics`, merged PR #3):** #3 (decorative-image semantics), #4 (selectAction button role/label), #5 (Rating value/adjustable semantics — also fixed a latent runtime assertion in interactive rating), #6 (carousel dot labels).
- **Implemented (branch `fix/input-label-semantics`, merged PR #5):** #7 — but the finding was **partly inaccurate**. Empirical semantics dumps showed `Input.Text`/`Number`/`Date` **already** associate their label (via the underlying `TextFormField`). The real gaps were `Input.Toggle` (Switch), `Input.Rating` (star control), and `Input.ChoiceSet` (compact/filtered/expanded), now fixed per-control: `MergeSemantics` for single controls (toggle, rating, compact/filtered dropdown), and a `Semantics` group label for expanded (options stay individually focusable — a blanket merge would have collapsed them). Covered by `test/input_label_semantics_test.dart`.
- **Still open — #9 (localization):** hard-coded English strings remain (`'Refresh card'` at `adaptive_card_element.dart:425,428`; `'Rating'` in `rating_stars.dart:164,176`; `'Go to slide N'` in `carousel.dart:177`; `'choiceFilter'` fallback in `choice_filter.dart:44`). Deferred to a separate repo-wide l10n effort.
- **Implemented (branch `fix/textblock-heading-level-and-factset-semantics`):** #10 — TextBlock heading now emits `Semantics(headingLevel:)` from HostConfig `textBlock.headingLevel` (default 2, clamped 1–6); an icon carrying a `selectAction` no longer double-announces its Fluent token (the `AdaptiveTappable` button label wins). **Partial:** a standalone icon still announces its token — the AC `Icon` element has no `altText`, so there is no author signal to mark it purely decorative; full suppression would need a schema/`role` addition.
- **Implemented (branch `fix/textblock-heading-level-and-factset-semantics`):** #11 (FactSet, was the unnumbered follow-up) — the two-column layout is unchanged (golden-safe); each fact's title node now carries the combined `"title: value"` label and the value column is wrapped in `ExcludeSemantics`, so a screen reader announces each fact as one unit in reading order. **Trade-off:** interactive markdown links inside a fact _value_ lose their own semantics (fact values are short text in practice); a per-row `MergeSemantics` restructure would preserve them but changes the visual layout and all FactSet goldens.
  **Reviewer:** AI-assisted static audit

This review evaluates the core library for **missing or broken accessibility
semantics** and **widget key creation**, measured against the project's own
requirements.

---

## Requirements evaluated against

| Source                                        | Requirement                                                                                                 |
| --------------------------------------------- | ----------------------------------------------------------------------------------------------------------- |
| `AGENTS.md` → Semantic Labels and Widget Keys | "Apply semantic labels for accessibility (for example, use `altText` from card JSON for images and icons)." |
| `AGENTS.md` → Semantic Labels and Widget Keys | "Use deterministic keys via `generateAdaptiveWidgetKey()` and `generateWidgetKey()`."                       |
| `AGENTS.md` → Documentation Philosophy        | "All UI strings must be localized in `.arb` files."                                                         |
| `docs/AdaptiveWidget-Key-Generation.md`       | Keys "must be generated **deterministically** from `adaptiveMap`."                                          |
| `docs/form-inputs.md:353-356`                 | Adaptive wrapper key = `{id}_adaptive`; field key = `{id}`.                                                 |
| Adaptive Cards spec                           | `Image.altText`; `selectAction` targets operable & labeled; inputs labeled.                                 |

Severity legend: 🔴 high · 🟡 medium · ⚪ low.

---

## Summary

| #   | Area         | Finding                                                                               | Severity            | Status                                                                    |
| --- | ------------ | ------------------------------------------------------------------------------------- | ------------------- | ------------------------------------------------------------------------- |
| 1   | Keys         | `AdaptiveTappable` mints a fresh UUID key on every build (non-deterministic)          | 🔴                  | ✅ Fixed (PR #4)                                                          |
| 2   | Keys         | `AdaptiveTappable` keys off `type`, ignoring the element `id`                         | 🔴 (same fix as #1) | ✅ Fixed (PR #4)                                                          |
| 3   | Semantics    | Decorative / alt-less images announce literal `"alt text not set"`                    | 🔴                  | ✅ Fixed (PR #3)                                                          |
| 4   | Semantics    | `selectAction` wrapper has no button role or accessible name                          | 🔴                  | ✅ Fixed (PR #3)                                                          |
| 5   | Semantics    | Rating control exposes no value/role semantics                                        | 🔴                  | ✅ Fixed (PR #3)                                                          |
| 6   | Semantics    | Carousel page indicators are unlabeled                                                | 🟡                  | ✅ Fixed (PR #3)                                                          |
| 7   | Semantics    | Input labels are not programmatically associated with their fields                    | 🟡                  | ✅ Fixed (PR #5)                                                          |
| 8   | Keys         | `choice_filter.dart` bypasses the key generators                                      | 🟡                  | ✅ Fixed (PR #4) — `'choiceFilter'` retained only as a defensive fallback |
| 9   | Localization | Hard-coded English accessibility strings                                              | 🟡                  | ⬜ Open — deferred to repo-wide l10n                                      |
| 10  | Semantics    | TextBlock heading has no heading level; icon token always announced                   | ⚪                  | ✅ Fixed (heading level) · partial (icon: dup announcement removed)       |
| 11  | Semantics    | **Follow-up:** `FactSet` title/value read as disconnected nodes (no `MergeSemantics`) | 🟡                  | ✅ Fixed (combined label on title, value excluded)                        |

---

## Key generation

> **Governing principle — all keys come from the generator functions.**
> Every widget key must be produced by the shared helpers in `utils.dart`
> (`generateAdaptiveWidgetKey`, `generateWidgetKey`, `generateWidgetKeyFromId`),
> never by inline `ValueKey('...')` construction or ad-hoc string literals. This
> is the existing contract in `docs/AdaptiveWidget-Key-Generation.md` ("Tests
> must use the same generator functions — never hard-code the key string"). The
> point is symmetry: tests call the _same_ function on the element's
> `adaptiveMap`/id to locate the widget, so a key-format change updates both
> sides at once. **Every fix below routes through a function** — including any
> new seed (e.g. table-cell ids), which must be produced by a named helper that
> tests can import, not built inline.

**Inventory of key construction that bypasses the shared generators:**

| Site                                 | Current                                                                     | Verdict                                                                     |
| ------------------------------------ | --------------------------------------------------------------------------- | --------------------------------------------------------------------------- |
| `additional.dart:87`                 | `ValueKey<String>(uniqueId)` (random UUID)                                  | 🔴 finding #1 — inline **and** non-deterministic                            |
| `choice_filter.dart:83,128,146`      | `ValueKey(keyValue)` / `'${keyValue}_${title}'` w/ `'choiceFilter'` literal | 🟡 finding #8 — inline                                                      |
| `flutter_raw_adaptive_card.dart:409` | `ValueKey(inputId)`                                                         | 🟡 inline; should be `generateWidgetKeyFromId(inputId)`                     |
| `table.dart:50-63`                   | `columnKey` / `cellKey` / `rowKey` / `tableColumnKey` static helpers        | 🟢 _are_ functions, but **local to the widget** and build `ValueKey` inline |
| `adaptive_card_element.dart:78`      | `GlobalKey<FormState>()`                                                    | ⚪ ok — internal Form handle, not an addressable element key                |

The `table.dart` helpers are the right idea done in the wrong place: they are
named functions a test could call, but they live on the widget class and
duplicate the `ValueKey('${...}')` format instead of delegating to
`generateWidgetKeyFromId`. **Recommendation:** promote these into `utils.dart`
(or have them delegate to `generateWidgetKeyFromId(tableId, suffix: ...)`) so
there is a single source of the key format that both production and tests
import.

### 🔴 1. `AdaptiveTappable` generates a non-deterministic key on every build

**File:** `lib/src/additional.dart:77-90`

```dart
factory AdaptiveTappable({
  required Widget child,
  required Map<String, dynamic> adaptiveMap,
}) {
  final uniqueId = UUIDGenerator().generateUniqueId(type: adaptiveMap['type']); // fresh UUID every call
  return AdaptiveTappable._(
    adaptiveMap: adaptiveMap,
    id: uniqueId,
    key: ValueKey<String>(uniqueId),
    child: child,
  );
}
```

`AdaptiveTappable` is constructed inside `build()` (e.g. `image.dart:83`,
`icon.dart:89`). Because the factory mints a **new UUID on each invocation**,
the `ValueKey` changes on **every rebuild**.

**"Actions don't have ids, so there's nothing to seed from" — addressed.**
`AdaptiveTappable` does **not** wrap actions. It wraps the **element/container
that carries a `selectAction`** and reads `adaptiveMap['selectAction']`
(`additional.dart:123,125,138`). Every call site passes a typed element map that
already has an id (`injectIds()` injects one at load for any node with a
`"type"`):

| Call site                        | Wrapped map          | id source                     |
| -------------------------------- | -------------------- | ----------------------------- |
| `adaptive_card_element.dart:342` | card `adaptiveMap`   | card id                       |
| `image.dart:83`                  | Image element        | injected                      |
| `icon.dart:89`                   | Icon element         | injected                      |
| `container.dart:142`             | Container            | injected                      |
| `column.dart:185`                | Column               | injected                      |
| `column_set.dart:99`             | ColumnSet            | injected                      |
| `table.dart:273`                 | `TableCell.toJson()` | **nullable** — needs fallback |

So a deterministic seed _is_ available (the wrapped element's id). The only case
without a guaranteed id is the **table cell** — and even there the fix is a
stable computed seed, not a per-build random UUID.

**Impact**

- Violates the deterministic-key contract (`AdaptiveWidget-Key-Generation.md`,
  `AGENTS.md`).
- Flutter cannot reuse the element → the wrapped `InkWell` **and its child
  subtree (image/icon) are torn down and rebuilt each frame** the parent
  rebuilds. For network images this risks reload/flicker and lost ink-splash
  state.
- The wrapper is **unfindable in tests** — no stable key derives from the
  element `id`.

**Fix direction:** derive the key deterministically from the wrapped element's
`id`, e.g. `generateWidgetKeyFromId(loadId(adaptiveMap), suffix: 'selectAction')`,
and drop the per-build UUID. Use the `_selectAction` suffix (not `_adaptive`) so
the tap wrapper does not collide with the wrapped element's own
`{id}_adaptive` key. A changing `ValueKey` breaks Flutter element reuse
(`canUpdate` compares keys even for a single child), which is the core defect.
This resolves #2 as well.

#### Plan for missing ids (ids are optional on layout elements)

The Adaptive Cards spec makes `id` **optional** on `Container`, `Column`,
`ColumnSet`, `Image`, `Icon`, etc. That does **not** require making `id`
mandatory or adding a validation gate — the loader already guarantees an id on
every typed node before the tree is built.

**Existing invariant — id injection at load.** `flutter_raw_adaptive_card.dart:111-114`
deep-copies the host map in `initState` and runs `injectIds()` on it:

```dart
static Map<String, dynamic> _deepCopyBaseline(Map<String, dynamic> map) {
  final copy = json.decode(json.encode(map)) as Map<String, dynamic>;
  injectIds(copy); // any node with a "type" and no "id" gets a synthetic id
  return copy;
}
```

`injectIds()` (`utils.dart:420`) injects an id into **any node that has a
`"type"`**. Containers, columns, column-sets, images, and icons all have a
`"type"`, so all receive a stable id in `_baselineMap` — the map the widget tree
is built from. The id is injected **once** and persists for the card's lifetime,
so `loadId(adaptiveMap)` returns the same value on every rebuild.

**Consequence:** for every layout element except table cells, there is **no
"id-missing" case at build time** — author-optional in JSON, always present after
injection. `AdaptiveTappable` simply needs to _read_ that id via
`loadId(adaptiveMap)` instead of minting a fresh UUID.

**The one real gap — the `AdaptiveTappable` inside a table cell.** The cell
_widget_ already gets a deterministic key from the existing
`AdaptiveTable.cellKey(tableKey, row, col)` helper (`table.dart:54`), so the cell
itself is fine. The gap is narrower: `table.dart:273` wraps the cell content in
`AdaptiveTappable(adaptiveMap: cellModel.toJson(), ...)`, and
`TableCellModel.toJson()` emits **no `"type"` key** and only emits `id` when
non-null — so `injectIds()` never touches it and `loadId` finds nothing, sending
it back to the per-build random UUID (finding #1).

Plan: seed the cell's `AdaptiveTappable` from the **same positional identity**
the cell key already uses. Rather than a new bespoke string, reuse/derive from
`cellKey(tableKey, row, col)` (once promoted to a shared helper per the
inventory above) so production and tests share one source. Per the governing
principle, do not inline the seed at either the production or the test site.

**Decision: do not make `id` mandatory and do not add a validation gate.** That
would violate the AC spec (id is optional on layout elements) and reject valid
host cards. `injectIds` is exactly the mechanism that removes the need for a
gate. The invariant to lean on is: _every rendered node has an id post-injection;
keys derive from it._

**Caveat (pre-existing, not introduced here):** the injected id is a random
`UniqueKey`-based UUID, so it is stable **across rebuilds** (fixing the churn)
but **not deterministic across loads** — an element that omits an author id
still cannot be found by a predictable key in integration tests. This is an
existing library property (`AdaptiveWidget-Key-Generation.md`). Making injected
ids **path-based** (`body[0].columns[1]`) for cross-load determinism is a
separate, larger change worth its own decision.

### 🔴 2. `AdaptiveTappable` keys off `type`, ignoring the element `id`

Same code path as #1. Because the id is a `type`-based UUID, the wrapper can
never satisfy the `{id}_adaptive` contract in `docs/form-inputs.md:353-356`.
Fixed together with #1.

### 🟡 8. `choice_filter.dart` bypasses the key generators

**File:** `lib/src/cards/inputs/choice_filter.dart:73-83`

```dart
final String keyValue = (widget.key is ValueKey<String>)
    ? (widget.key! as ValueKey<String>).value
    : 'choiceFilter';
...
child: TextFormField(
  key: ValueKey(keyValue),
  ...
```

Reconstructs a key from `widget.key` with a hard-coded `'choiceFilter'`
fallback instead of `generateWidgetKey(...)`. Works today but drifts from the
governing principle — the inline `ValueKey(...)` and literal `'choiceFilter'`
mean a test cannot reach this field through a shared generator.

**Fix direction:** build the key from the element via
`generateWidgetKey(adaptiveMap, suffix: ...)` (or `generateWidgetKeyFromId`) and
have the test call the identical function; remove the inline `ValueKey` and the
`'choiceFilter'` string literal.

**Done well:** `execute.dart`, `text_block.dart:165`, and the standard element
constructors correctly use `generateAdaptiveWidgetKey` / `generateWidgetKey`.

---

## Accessibility semantics

### 🔴 3. Decorative / alt-less images announce the literal string `"alt text not set"`

**File:** `lib/src/utils/adaptive_image_utils.dart:31`

```dart
final resolvedSemanticsLabel = semanticsLabel ?? 'alt text not set';
```

This default is applied to **every** image path (network, memory, SVG,
broken-image icon). Background/decorative images call
`getImage(..., semanticsLabel: null)` (`adaptive_mixins.dart:125`), so a screen
reader reads out **"alt text not set"** for purely decorative art. This is
_worse_ than correct behavior: a Flutter `Image` with a null `semanticLabel` is
excluded from the semantics tree.

Two violations in one line:

- **Broken semantics** — noise for assistive tech; decorative images should be
  excluded, not labeled.
- **Localization** — hard-coded English UI string.

**Fix direction:** pass `null` through for decorative images (exclude from
semantics); never substitute a placeholder label.

### 🔴 4. `selectAction` wrapper has no button role or accessible name

**File:** `lib/src/additional.dart:134-141`

```dart
return action == null
    ? widget.child
    : InkWell(
        onTap: () => action?.tap(...),
        child: widget.child,
      );
```

Exposes a tap action but **no `Semantics(button: true)` and no label** from the
`selectAction`'s `title`/`tooltip`. A screen-reader user hears the child content
(or nothing, for an alt-less image) with no indication it is actionable or what
it does.

**Fix direction:** wrap in `Semantics(button: true, label: <selectAction title/tooltip>, child: InkWell(...))`.

### 🔴 5. Rating control exposes no value/role semantics

**File:** `lib/src/widgets/rating_stars.dart:132-150`

Interactive stars are raw `GestureDetector`s; read-only stars are bare `Icon`s.
There is **no `Semantics`** anywhere:

- Interactive: no label, no button/slider role, no increase/decrease actions,
  no announced value.
- Read-only (`Input.Rating` display and the `Rating` element): no
  "_x of y stars_" value announcement.

A screen-reader user cannot perceive or operate the rating.

**Fix direction:** wrap the row in a `Semantics` node with a value
("`$value of $max stars`") and, for the interactive case, slider/adjustable
semantics with increase/decrease actions.

### 🟡 6. Carousel page indicators are unlabeled

**File:** `lib/src/cards/elements/carousel.dart:175`

Dot indicators are `GestureDetector(onTap: …)` with no `Semantics` label
(e.g. "Go to slide N") and no selected-state semantics.

### 🟡 7. Input labels are not programmatically associated with their fields

**File:** `lib/src/utils/utils.dart:220-294` (`loadLabel`)

`loadLabel()` renders a **separate visual `Text.rich`** above each input (used
by `text/number/date/rating/choice_set/toggle`). It is not wired to the field
via `InputDecoration.labelText` or a `Semantics(label:)` link, so focusing the
`TextFormField` does **not** announce the label. The visual label exists; the
programmatic association does not.

**Fix direction:** attach the label to the field's `InputDecoration` (or wrap
the field in `Semantics(label:)`) so focus announces it, while keeping the
existing visual layout.

### 🟡 9. Hard-coded English accessibility strings

**File:** `lib/src/cards/adaptive_card_element.dart:425,428`

```dart
Semantics(
  button: true,
  label: 'Refresh card',
  child: IconButton(icon: const Icon(Icons.refresh), tooltip: 'Refresh card', ...),
)
```

The `Semantics(button: true, label: …)` pattern here is the model to follow
elsewhere, but the literal strings — plus `'alt text not set'` from #3 — violate
the localization requirement (`.arb`).

### ⚪ 10. Minor / acknowledged — ✅ heading level fixed · icon partial

- **Fixed:** `text_block.dart` now sets `Semantics(headingLevel:)` for heading-
  styled TextBlocks, sourced from HostConfig `textBlock.headingLevel` (default 2,
  clamped to 1–6; `null` for non-headings, since the `Semantics` widget accepts
  only `null` or 1–6). AC has no per-element heading level, so the HostConfig
  value applies to all heading TextBlocks.
- **Partial:** `icon.dart` previously passed `semanticLabel: name` (the Fluent
  token, e.g. `"Home"`) on every icon. It now suppresses that token when the
  icon carries a `selectAction` whose `title`/`tooltip` already labels the
  `AdaptiveTappable` button, removing the double announcement. A **standalone**
  icon still announces the token — the AC `Icon` element exposes no `altText`,
  so there is no author signal distinguishing a meaningful icon from a purely
  decorative one. Full decorative suppression would require a schema/`role`
  addition and is out of scope here.

### 🟡 11. `FactSet` title/value announced as disconnected nodes — ✅ fixed

**File:** `lib/src/cards/containers/fact_set.dart`

`FactSet` renders titles and values in **two parallel columns** (a `Row` of a
title `Column` and a value `Column`), so each fact's title and value are
separate semantics nodes with no association — a screen reader reads the title,
then later the value, as unrelated items.

**Fix:** the two-column visual layout is left unchanged (golden-safe). Each
fact's title node now carries the combined `"${title}: ${value}"` label, and the
value column is wrapped in `ExcludeSemantics`. In geometric reading order the
screen reader announces each fact once, as a unit ("Name: John"), top to bottom.

**Trade-off:** interactive markdown links inside a fact **value** lose their own
semantics because the value column is excluded. Fact values are short text in
practice, so this is acceptable; the alternative — restructuring to per-fact
`Row`s wrapped in `MergeSemantics` — preserves link semantics but changes the
visual layout (title/value alignment) and every FactSet golden, so it was not
taken.

---

## What's done well

- Actions render via `ElevatedButton` (`icon_button.dart`) → correct built-in
  button semantics + `Tooltip`.
- `Image`/`Media` correctly forward `altText` → `semanticsLabel`
  (`image.dart:90`, `media.dart:217`).
- `TextBlock`/`RichTextBlock` wrap in `Semantics`, and `_RefreshAffordance` is a
  clean `Semantics(button:true, label:…)` model.
- Standard elements follow the deterministic key pattern correctly.

---

## Suggested remediation order

1. **#1 / #2** — non-deterministic `AdaptiveTappable` key (correctness + perf +
   testability + contract). Add a regression test asserting a stable key.
2. **#3** — `"alt text not set"` default (regresses decorative-image a11y; quick
   fix + localization).
3. **#4 / #5** — add `Semantics` roles/labels/values to `selectAction` and
   Rating.
4. **#7** — associate input labels with fields.
5. **#6 / #8 / #9 / #10** — contract/localization/polish.

Suggested branching: one branch for **#1 + #3** (small, high-impact, each needs
a regression test), a second branch for the Semantics gaps (**#4 / #5 / #6**).
